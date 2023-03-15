FROM kartoza/postgis:13.0

RUN mkdir osm

COPY flex-config/charging_station_tags_v1.7.lua osm/style.lua

RUN apt update
RUN apt install -y build-essential git curl
# RUN sudo apt install -y libgdal-dev
# RUN export C_INCLUDE_PATH=/usr/include/gdal
# RUN export CPLUS_INCLUDE_PATH=/usr/include/gdal

# RUN psql -d postgres -U postgres

WORKDIR osm
RUN git clone https://github.com/openstreetmap/osm2pgsql.git
WORKDIR osm2pgsql
RUN apt install -y make cmake g++ libboost-dev libboost-system-dev \
  libboost-filesystem-dev libexpat1-dev zlib1g-dev libpotrace-dev cimg-dev \
  libbz2-dev libpq-dev libproj-dev lua5.3 liblua5.3-dev pandoc
RUN mkdir build
WORKDIR build
RUN cmake ..
RUN make
RUN make install
RUN apt install -y libluajit-5.1-dev
RUN cmake -D WITH_LUAJIT=ON ..
WORKDIR ..

RUN apt install -y osmium-tool

# https gives a certificate error, wtf?
RUN wget --inet4-only -O osm.pbf http://download.geofabrik.de/europe/luxembourg-latest.osm.pbf

RUN osmium \
    tags-filter \
    osm.pbf \
    amenity=charging_station \
    boundary=administrative \
    n/place \
    -o osm_filtered.pbf

RUN export PGPASS=$POSTGRES_PASS
RUN osm2pgsql \
    -l --hstore \
    -d $POSTGRES_DBNAME \
    -U $POSTGRES_USER \
    -H $POSTGRES_HOST \
    -P $POSTGRES_PORT \
    -O flex \
    -S style.lua \
    osm_filtered.pbf
