FROM python:3.8.6

RUN mkdir repo
WORKDIR repo

RUN apt update
RUN apt install -y build-essential
RUN apt install -y libpq-dev
RUN apt install -y libgdal-dev
RUN export C_INCLUDE_PATH=/usr/include/gdal
RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal

COPY requirements.txt requirements.txt
COPY app.py app.py
COPY sql sql

RUN pip install -r requirements.txt

EXPOSE 80

ENTRYPOINT ["python", "app.py"]
