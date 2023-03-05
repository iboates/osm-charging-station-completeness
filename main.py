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


def _filter_pbf(pbf, filtered_pbf):

    args = [
        "osmium",
        "tags-filter",
        pbf,
        # remember, filter args are ALWAYS treated as chained ORs, not chained ANDs
        "amenity=charging_station",
        "boundary=administrative",
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


def _postprocess_osm_country_boundaries(conn):

    with conn.cursor() as cur:
        cur.execute(open("flex-config/country_boundaries_to_polygon.sql").read())


class CLI:

    def __init__(self):
        load_dotenv()
        try:
            self.conn = pg2.connect(host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"), dbname=os.getenv("DB_NAME"),
                               user=os.getenv("DB_USER"), password=os.getenv("DB_PASS"))
            self.conn.autocommit = True
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

    def create_postgis(self, pbf="data/final.pdf", flex_config="flex-config/charging_station_tags_v1.7.lua"):

        _osm2pgsql(pbf, os.getenv("DB_NAME"), os.getenv("DB_USER"), os.getenv("DB_PASS"), schema="public",
                   host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"), flex_config=flex_config)
        _postprocess_osm_country_boundaries(self.conn)

    def analyze_capacity(self, country_names):

        if self.conn is None:
            raise RuntimeError("Could not connect to PostGIS database.")

        if not isinstance(country_names, tuple):
            country_names = tuple(cn.lower for cn in country_names.split(","))

        fig = make_subplots(rows=1, cols=1)
        query = f"""
            select
                -- cs.node_id,
                c.name as country,
                cs.capacity as capacity,
                count(cs.capacity) as num
            from
                charging_station cs
                left join socket s on cs.node_id = s.node_id
                left join country c on ST_Intersects(c.geom, cs.geom)
            where
               lower(c.name) in {country_names}
            group by
                c.name,
                cs.capacity
            order by
                c.name asc,
                num desc
            ;
        """
        with self.conn.cursor() as cur:
            cur.execute(query)
            tag_df = pd.DataFrame(cur.fetchall(), columns=["count", "tag_value"])

        trace = go.Bar(
            y=tag_df["count"].to_list(),
            x=tag_df["tag_value"].to_list()
        )
        fig.add_trace(trace, row=1, col=1)

        fig.show()

    def export_osm_ids_with_errors(self, sql_file="sql/capacity_with_suspicious_value.sql", out_file="data/out/errors.gpkg"):

        if self.conn is None:
            raise RuntimeError("Could not connect to PostGIS database.")

        with open(sql_file) as f:
            query = f.read()
        gdf = gpd.read_postgis(query, self.conn)
        gdf.to_file(out_file)


if __name__ == "__main__":
    fire.Fire(CLI)
