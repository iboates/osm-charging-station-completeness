FROM bitnami/minideb

RUN apt update
RUN apt install -y build-essential git curl

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

# COPY run.sh run.sh
# RUN chmod +x run.sh
# COPY flex-config/charging_station_tags_v1.7.lua charging_station_tags_v1.7.lua

RUN apt install -y osmium-tool
