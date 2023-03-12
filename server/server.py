import json
import os

from dotenv import load_dotenv
from flask import Flask, request, make_response
import geopandas as gpd
from werkzeug.exceptions import HTTPException
import sqlalchemy as sa
import pandas as pd

load_dotenv()
app = Flask(__name__)


@app.route("/status")
def status():
    return "d-( ͡° ͜ʖ ͡°) OK!\n"


@app.route("/completeness", methods=["POST"])
def completeness():

    with sa.create_engine as engine:
        df = pd.read_sql(open("../s"))