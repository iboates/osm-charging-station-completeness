import json
import os
import pathlib
from datetime import datetime

from dotenv import load_dotenv
from flask import Flask, request, make_response, jsonify
import sqlalchemy as sa
import pandas as pd
import geojson
import numpy as np


HERE = pathlib.Path(__file__).parent.resolve()

load_dotenv()

app = Flask(__name__)


class CSCException(Exception):
    pass


def csc_exception_handler(e, errors=None):
    res = {'message': str(e)}
    if errors:
        res["errors"] = errors
    return jsonify(res), 400


app.register_error_handler(CSCException, csc_exception_handler)


def _parse_study_area(study_area):

    if study_area is None:
        study_area = geojson.load(open("data/world.geojson"))

    study_area = geojson.GeoJSON(study_area)

    if not study_area.is_valid:
        raise CSCException("GeoJSON is invalid", study_area.errors())

    if study_area.get("features") is not None:
        if len(study_area["features"]) != 1:
            raise CSCException("POSTed GeoJSON must have exactly one feature in it and be a Polygon or Multipolygon.")
        first_feature = study_area["features"][0]["geometry"]
    else:
        first_feature = study_area

    if first_feature["type"] not in ("Polygon", "MultiPolygon"):
        raise CSCException("POSTed GeoJSON must have exactly one feature in it and be a Polygon or Multipolygon.")

    return first_feature


def _parse_query_timestamp(query_timestamp):

    if query_timestamp is None:
        return datetime.now().strftime(format="%Y-%m-%d %H:%M")
    try:
        return datetime.fromisoformat(query_timestamp).strftime(format="%Y-%m-%d %H:%M:%S")
    except ValueError:
        raise CSCException("Invalid timestamp parameter, must be ISO format.")


@app.route("/status", methods=["GET"])
def status():
    return "OK"


@app.route("/completeness", methods=["POST"])
def completeness():

    query_timestamp = _parse_query_timestamp(request.json.get("timestamp"))

    study_area_geojson = request.json.get("studyArea")
    study_area = _parse_study_area(study_area_geojson)

    engine = sa.create_engine(f'postgresql://{os.getenv("DB_USER")}:{os.getenv("DB_PASS")}@{os.getenv("DB_HOST")}'
                              f':{os.getenv("DB_PORT")}/{os.getenv("DB_NAME")}')
    df = pd.read_sql(sa.text(open(f"{HERE}/sql/summarize_completeness.sql").read()), engine,
                           params={"study_area": json.dumps(study_area),
                                   "query_timestamp": query_timestamp})
    df = df.set_index("tag", drop=True).fillna(np.nan).replace([np.nan], [None])
    engine.dispose()
    return make_response(df.to_dict(orient="index"))


@app.route("/completeness_interval", methods=["POST"])
def completeness_interval():

    query_timestamp_start = _parse_query_timestamp(request.json["timestamp"]["start"])
    query_timestamp_end = _parse_query_timestamp(request.json["timestamp"]["end"])

    study_area_geojson = request.json.get("studyArea")
    study_area = _parse_study_area(study_area_geojson)

    engine = sa.create_engine(f'postgresql://{os.getenv("DB_USER")}:{os.getenv("DB_PASS")}@{os.getenv("DB_HOST")}'
                              f':{os.getenv("DB_PORT")}/{os.getenv("DB_NAME")}')

    summary_df = pd.read_sql(sa.text(open(f"{HERE}/sql/summarize_completeness_interval.sql").read()), engine,
                           params={"study_area": json.dumps(study_area),
                                   "start_time": query_timestamp_start,
                                   "end_time": query_timestamp_end})
    summary_df = summary_df.set_index("tag", drop=True).fillna(np.nan).replace([np.nan], [None])
    summary = summary_df.to_dict(orient="index")

    timestamps_df = pd.read_sql(sa.text(open(f"{HERE}/sql/get_timestamps.sql").read()), engine,
                           params={"start_time": query_timestamp_start,
                                   "end_time": query_timestamp_end})
    timestamps = timestamps_df["timestamp"].apply(lambda x: x.isoformat(timespec="minutes")).to_list()

    engine.dispose()

    ret = {
        "timestamps": timestamps,
        "summary": summary
    }

    return make_response(ret)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
