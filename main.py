import os
import shutil
import subprocess as sp
import warnings

import fire
import requests
from dotenv import load_dotenv
import pandas as pd
import geopandas as gpd
import psycopg2 as pg2
from plotly.subplots import make_subplots
import plotly.graph_objects as go
from tqdm import tqdm
import sqlalchemy as sa


def _filter_pbf(pbf, filtered_pbf):

    args = [
        "osmium",
        "tags-filter",
        pbf,
        # remember, filter args are ALWAYS treated as chained ORs, not chained ANDs
        "amenity=charging_station",
        "boundary=administrative",
        "n/place",
        "-o", filtered_pbf,
        "--overwrite"
    ]
    sp.run(args)


def _merge_pbfs(pbf_1, pbf_2, out_pbf):

    args = [
        "osmium",
        "merge",
        "--overwrite",
        pbf_1,
        pbf_2,
        "-o", out_pbf,
    ]
    sp.run(args)


def _download(pbf_url, pbf):
    if not os.path.exists(pbf):
        with requests.get(pbf_url, stream=True) as r:
            with open(pbf, 'wb') as f:
                shutil.copyfileobj(r.raw, f)


def _osm2pgsql(pbf, database, username, password, schema, host, port, flex_config, slim=False):

    args = [
        "osm2pgsql",
        "-d", database,
        "-U", username,
        "-H", host,
        "-P", str(port),
        "-l",  # EPSG 4326
        "--hstore",
        "-O", "flex",
        "-S", flex_config,
        "-r", "pbf",
        pbf,
    ]
    print(args)

    if schema != "public":
        args = args[:-1] + [f"--output-pgsql-schema={schema}"] + [args[-1]]
    if slim:
        args = [*args[:-2], "--slim", args[-1]]
    sp.run(args, env={**os.environ.copy(), "PGPASSWORD": password})

def _execute_sql(engine, sql_file):

    engine.execute(open(sql_file).read())


class CLI:

    def __init__(self):
        load_dotenv()
        try:
            self.conn = pg2.connect(host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"), dbname=os.getenv("DB_NAME"),
                               user=os.getenv("DB_USER"), password=os.getenv("DB_PASS"))
            self.conn.autocommit = True
            self.engine = sa.create_engine(f'postgresql://{os.getenv("DB_USER")}:{os.getenv("DB_PASS")}@{os.getenv("DB_HOST")}:{os.getenv("DB_PORT")}/{os.getenv("DB_NAME")}')
        except pg2.OperationalError:
            warnings.warn("Could not connect to PostGIS database.")
            self.conn = None

    def compile_pbfs(self, pbf_urls, final_pbf="data/final.pbf", work_dir="data"):

        if isinstance(pbf_urls, str):
            pbf_urls = pbf_urls.split(",")

        if os.path.exists(final_pbf):
            os.remove(final_pbf)

        pbar = tqdm(total=len(pbf_urls))
        for pbf_url in tqdm(pbf_urls):
            pbf = f"{work_dir}/{pbf_url.split('/')[-1]}"
            pbf_filtered = pbf.replace(".osm.pbf", "_charging_stations.osm.pbf")
            pbar.set_description(pbf)

            _download(pbf_url, pbf)
            _filter_pbf(pbf, pbf_filtered)
            if not os.path.exists(final_pbf):
                shutil.move(pbf_filtered, final_pbf)
            else:
                _merge_pbfs(pbf_filtered, final_pbf, final_pbf.replace(".pbf", ".2.pbf"))
                # dont know why, but overwriting final.pbf directly with merge results in a smaller output pbf
                shutil.move(final_pbf.replace(".pbf", ".2.pbf"), final_pbf)
            pbar.update(1)

    def create_postgis(self, pbf="data/final.pbf", flex_config="flex-config/charging_station_tags_v1.7.lua"):

        _osm2pgsql(pbf, os.getenv("DB_NAME"), os.getenv("DB_USER"), os.getenv("DB_PASS"), schema="public",
                   host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"), flex_config=flex_config)
        _execute_sql(self.conn, "flex-config/country_boundaries_to_polygon.sql")
        _execute_sql(self.conn, "flex-config/cs_completeness.sql")


    def execute_sql(self, sql_file):

        with self.engine.connect() as connection:
            connection.execute(sa.text(open(sql_file).read()))

    def summarize(self, sql_file=None, tags=None):

        if sql_file is None:
            sql_file = "sql/get_completeness.sql"

        if tags is None:
            tags = [
                "brand",
                "operator",
                "capacity",
                "authentication",
                "fee",
                "parking_fee",
                "maxstay",
                "opening_hours",
                "payment",
                "socket",
                "voltage",
                "output",
                "current",
            ]

        ALLOWED_TAGS = [
            "brand",
            "operator",
            "capacity",
            "authentication",
            "fee",
            "parking_fee",
            "maxstay",
            "opening_hours",
            "payment",
            "socket",
            "voltage",
            "output",
            "current",
        ]

        SOCKET_TAGS = {
            "socket": ":socket:type",
            "number": ":socket:type:number",
            "voltage": ":socket:type:output",
            "output": ":socket:type:voltage",
            "current": ":socket:type:current"
        }

        with open(sql_file) as f:
            query = f.read()
        with open("sql/tag_fragment.sql") as f:
            tag_fragment = f.read()

        tag_fragment_replacements = []
        for tag in tags:
            if tag not in ALLOWED_TAGS:
                raise ValueError(f"Invalid tag `{tag}`")
            tag_fragment_replacements.append(tag_fragment.replace("[[TAG_VALUE]]", tag))
        query = query.replace("[[TAG_FRAGMENTS]]", ",\n\n UNION ALL \n\n".join(tag_fragment_replacements))

        res = pd.read_sql(sa.text(query), self.engine)


if __name__ == "__main__":
    fire.Fire(CLI)
