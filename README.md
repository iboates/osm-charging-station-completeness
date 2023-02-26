# Analyzing OSM charging stations

To use:

1. Download (& potentially merge) pbfs (you can pass a comma-delimited list of download links:

```
python main.py compile_pbfs --pbf-urls="https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf"
```

2. Create the database

```
python main.py create_postgis --pbf="data/final.pbf"
```

3. Generate the error ids (pass custom sql file with `--sql_file=/path/to/your/sql/file.sql`)

```
python main.py get_osm_ids_with_errors
```