import json
import os
import pathlib

from dotenv import load_dotenv
from flask import Flask, request, make_response
import geopandas as gpd
from werkzeug.exceptions import HTTPException
import sqlalchemy as sa
import pandas as pd
import geojson
import numpy as np


HERE = pathlib.Path(__file__).parent.resolve()

load_dotenv()
app = Flask(__name__)


def _parse_study_area(study_area: geojson.GeoJSON):

    if not study_area.is_valid:
        raise ValueError("GeoJSON is invalid")

    if study_area.get("features") is not None:
        if len(study_area["features"]) != 1:
            raise ValueError("POSTed GeoJSON must have exactly one feature in it and be a Polygon or Multipolygon.")
        first_feature = study_area["features"][0]["geometry"]
    else:
        first_feature = study_area

    if first_feature["type"] not in ("Polygon", "Multipolygon"):
        raise ValueError("POSTed GeoJSON must have exactly one feature in it and be a Polygon or Multipolygon.")

    return first_feature


@app.route("/status")
def status():
    return "OK"


@app.route("/completeness", methods=["POST"])
def completeness():

    study_area = _parse_study_area(geojson.GeoJSON(request.json))
    engine = sa.create_engine(f'postgresql://{os.getenv("DB_USER")}:{os.getenv("DB_PASS")}@{os.getenv("DB_HOST")}'
                              f':{os.getenv("DB_PORT")}/{os.getenv("DB_NAME")}')
    df = pd.read_sql_query(sa.text(open(f"{HERE}/sql/summarize_completeness.sql").read()), engine,
                           params={"study_area": json.dumps(study_area)})
    df = df.set_index("tag", drop=True).fillna(np.nan).replace([np.nan], [None])
    engine.dispose()
    return make_response(df.to_dict(orient="index"))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
