#!/bin/bash

if [[ $1 == "update" ]]; then

  wget $PBF_DOWNLOAD_LINK -O osm.pbf

  # Filter out all the crap we don't need
  osmium tags-filter \
         osm.pbf \
         amenity=charging_station \
         boundary=administrative \
         n/place \
         -o osm_filtered.pbf

  # Set up credentials for processing & prod DBs
  touch ~/.pgpass
  chmod 0600 ~/.pgpass
#  echo "$PROCESS_DB_HOST:5432:127.0.0.1:freeman_process:freeman_process" >> ~/.pgpass
#  echo "$PROD_DB_HOST:5432:freeman_prod:freeman_prod:freeman_prod" >> ~/.pgpass
  echo "$PROCESS_DB_HOST:$PROCESS_DB_PORT:$PROCESS_DB_NAME:$PROCESS_DB_USER:$PROCESS_DB_PASS" >> ~/.pgpass
  echo "$PROD_DB_HOST:$PROD_DB_PORT:$PROD_DB_NAME:$PROD_DB_USER:$PROD_DB_PASS" >> ~/.pgpass

  # Process the data
  osm2pgsql -l \
            -O flex \
            -S data/charging_station_tags_v1.7.lua \
            -H $PROCESS_DB_HOST \
            -P $PROCESS_DB_PORT \
            -d $PROCESS_DB_NAME \
            -U $PROCESS_DB_USER \
            osm_filtered.pbf
  psql -h $PROCESS_DB_HOST -U $PROCESS_DB_USER -p $PROCESS_DB_PORT $PROCESS_DB_NAME \
       -f "data/country_boundaries_to_polygon.sql"
  psql -h $PROCESS_DB_HOST -U $PROCESS_DB_USER -p $PROCESS_DB_PORT $PROCESS_DB_NAME \
       -f "data/cs_completeness.sql"

  # Get every column from the cs_completeness table EXCEPT for id (it will cause a key constraint error later)
  cs_completeness_columns=$(
    psql -h $PROCESS_DB_HOST -d $PROCESS_DB_NAME -U $PROCESS_DB_USER -p $PROCESS_DB_PORT -t \
         -c "select array_agg(column_name) from information_schema.columns where table_name = 'cs_completeness' and column_name != 'id'" \
    | sed "s/{/\"/g" | sed "s/}/\"/g" | sed 's/,/","/g'
  )

  # Check what tables are in the prod DB (to see if we should be appending/replacing or just initializing
  tables=$(psql -h $PROD_DB_HOST -d $PROD_DB_NAME -U $PROD_DB_USER -p $PROD_DB_PORT -t \
    -c "select table_name from information_schema.tables where table_schema = 'public'")

  if [[ $tables == *"cs_completeness"* ]]; then

     # tables exist in prod db, append the contents of cs_completeness and replace the contents of every other table
    psql -h $PROD_DB_HOST -d $PROD_DB_NAME -U $PROD_DB_USER -p $PROD_DB_PORT \
         -c "truncate table charging_station; truncate table country; truncate table place; truncate table socket;"

    # Use \copy instead of pg_dump for cs_completeness because we have to avoid using the id column (primary key
    # constraint). The id column will get filled automatically, it is a SERIAL type
    psql -h $PROCESS_DB_HOST -U $PROCESS_DB_USER -p $PROCESS_DB_PORT $PROCESS_DB_NAME \
         -c "\copy cs_completeness ($cs_completeness_columns) TO STDOUT delimiter '|' csv ;" \
    | psql -h $PROD_DB_HOST -d $PROD_DB_NAME -U $PROD_DB_USER -p $PROD_DB_PORT \
      -c "\copy cs_completeness ($cs_completeness_columns) from STDIN with csv delimiter '|';"

    # Copy over the other tables (we don't care about preserving this history, it's all already in OSM itself
    pg_dump -h $PROCESS_DB_HOST -d $PROCESS_DB_NAME -U $PROCESS_DB_USER -p $PROCESS_DB_PORT \
            --no-owner --data-only \
            --table=public.charging_station \
            --table=public.country \
            --table=public.place \
            --table=public.socket \
    | psql -h $PROD_DB_HOST -d $PROD_DB_NAME -U $PROD_DB_USER -p $PROD_DB_PORT

  else

    # tables dont exist in prod db, just copy over the entire process DB
    pg_dump -h $PROCESS_DB_HOST -d $PROCESS_DB_NAME -U $PROCESS_DB_USER -p $PROCESS_DB_PORT \
            --no-owner \
    | psql -h $PROD_DB_HOST -d $PROD_DB_NAME -U $PROD_DB_USER -p $PROD_DB_PORT

  fi

fi
