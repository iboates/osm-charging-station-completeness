FROM bitnami/minideb

RUN apt update
RUN apt install -y build-essential git curl

RUN git clone --depth 1 --branch 1.8.1 https://github.com/openstreetmap/osm2pgsql.git
WORKDIR osm2pgsql
RUN apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev \
libpotrace-dev cimg-dev libbz2-dev libpq-dev libproj-dev lua5.3 liblua5.3-dev pandoc
RUN mkdir build
WORKDIR build
RUN cmake ..
RUN make
RUN make install
WORKDIR ..
RUN apt-get install -y libluajit-5.1-dev
WORKDIR ..
RUN rm -r osm2pgsql
# COPY run.sh run.sh
# RUN chmod +x run.sh


RUN apt install -y osmium-tool
RUN apt install -y wget
RUN apt install -y postgresql-client

COPY data data
COPY run.sh run.sh
# RUN touch ~/.pgpass
# RUN chmod 0600 ~/.pgpass
# RUN echo "ocm-process-db:5432:127.0.0.1:freeman_process:freeman_process" >> ~/.pgpass
# RUN echo "ocm-prod-db:5432:freeman_prod:freeman_prod:freeman_prod" >> ~/.pgpass

ENTRYPOINT [ "./run.sh" ]