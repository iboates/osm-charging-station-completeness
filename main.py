import os
import shutil
import subprocess as sp

from api import OCMAPI
import geopandas as gpd
import fire
import requests
from dotenv import load_dotenv
import pandas as pd
import psycopg2 as pg2
import plotly.express as px
from plotly.subplots import make_subplots
import plotly.graph_objects as go



def _filter_pbf(pbf, filtered_pbf):

    """
    osmium tags-filter australia-oceania-latest.osm.pbf /admin_level /highway /water /waterway /wetland
    -o australia-oceania-filtered.osm.pbf --overwrite
    """

    args = [
        "osmium",
        "tags-filter",
        pbf,
        "n/amenity=charging_station",
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


def _osm2pgsql(pbf, database, username, password, schema, host, port, slim=False):

    args = [
        "osm2pgsql",
        "-d", database,
        "-U", username,
        "-H", host,
        "-P", str(port),
        "-l",  # EPSG 4326
        "--hstore",
        "-O", "flex",
        "-S", "flex-config/charging_station_tags.lua",
        pbf,
    ]

    if schema != "public":
        args = args[:-1] + [f"--output-pgsql-schema={schema}"] + [args[-1]]
    if slim:
        args = [*args[:-2], "--slim", args[-1]]
    sp.run(args, env={**os.environ.copy(), "PGPASSWORD": password})


class CLI:

    def __init__(self):
        load_dotenv()
        self.conn = pg2.connect(host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"), dbname=os.getenv("DB_NAME"),
                           user=os.getenv("DB_USER"), password=os.getenv("DB_PASS"))
        self.conn.autocommit = True

    def compile_pbfs(self, pbf_urls, final_pbf="final.pbf", work_dir="data"):

        if isinstance(pbf_urls, str):
            pbf_urls = pbf_urls.split(",")

        if os.path.exists(final_pbf):
            os.remove(final_pbf)

        for pbf_url in pbf_urls:
            pbf = f"{work_dir}/{pbf_url.split('/')[-1]}"
            pbf_filtered = pbf.replace(".osm.pbf", "_charging_stations.osm.pbf")

            _download(pbf_url, pbf)
            _filter_pbf(pbf, pbf_filtered)
            if not os.path.exists(final_pbf):
                shutil.move(pbf_filtered, final_pbf)
            else:
                _merge_pbfs(pbf_filtered, final_pbf, final_pbf.replace(".pbf", ".2.pbf"))
                # dont know why, but overwriting final.pbf directly with merge results in a smaller output pbf
                shutil.move(final_pbf.replace(".pbf", ".2.pbf"), final_pbf)

    def create_postgis(self, pbf):

        _osm2pgsql(pbf, os.getenv("DB_NAME"), os.getenv("DB_USER"), os.getenv("DB_PASS"), schema="public",
                   host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"))

    def hstore_to_jsonb(self):

        query = """
            alter table planet_osm_point alter column tags type json using hstore_to_json(tags)
        """
        with self.conn.cursor() as cur:
            cur.execute(query)

    def analyze_tags(self, tags):

        if isinstance(tags, str):
            tags = tags.split(",")

        fig = make_subplots(rows=len(tags), cols=1)
        for i, tag in enumerate(tags, start=1):
            query = """
                select
                    count(*) as total,
                    tags->>%(tag)s as tag_value
                from
                    planet_osm_point
                group by
                    tags->>%(tag)s
                order by
                    count(*) desc
                ;
            """
            with self.conn.cursor() as cur:
                cur.execute(query, {"tag": tag})
                tag_df = pd.DataFrame(cur.fetchall(), columns=["count", "tag_value"])

            trace = go.Bar(
                y=tag_df["count"].to_list(),
                x=tag_df["tag_value"].to_list()
            )
            fig.add_trace(trace, row=i, col=1)

        fig.show()

    def _get_osm_ids_with_errors(self, sql_file):

        with self.conn.cursor() as cur:
            with open(sql_file) as f:
                cur.execute(f.read())
            error_osm_ids = [i[0] for i in cur.fetchall()]
        return error_osm_ids

    def summarize_errors(self):

        errors = {
            "capacity": {
                "using_power_output_with_high_certainty": self._get_osm_ids_with_errors("sql/capacity_using_power_output_with_high_certainty.sql"),
                "missing": self._get_osm_ids_with_errors("sql/capacity_missing.sql")
            },
            "socket": {

            },
            "eu_reference_number": {
                # todo: only for EU countries
                "missing": self._get_osm_ids_with_errors("sql/eu_reference_number_missing.sql")
            }
        }

        print()


if __name__ == "__main__":
    fire.Fire(CLI)