# OpenStreetMap Charging Station Completeness (CSC)

A little hobby project for carrying out periodic analysis of the completeness of tags related to electric vehicle
charging stations on OpenStreetMap. Also contains an API and associated web UI for making summary queries based on
location

## Local setup

Docker is recommended.

Build and launch everything. It will take a while to build the `csc-process` service because it has to compile
[osm2pgsql](https://github.com/osm2pgsql-dev/osm2pgsql))

```sh
docker compose up -d
```

Load the database with content. Everything is currently hardcoded so you don't need to change anything to get it
working. By default, it will process the OSM data for the German city of Karlsruhe and surrounding area. You can
change this by modifying the `PBF_DOWNLOAD_LINK` env var in the `csc-process` service in
[`./docker-compose.yaml`](docker-compose.yaml). Just keep in mind that larger OSM PBF files means longer processing
times.

```sh
docker compose run csc-process update
```

Once finished, you should have a table in your PostGIS database accessible from the `csc-prod-db` service, by default
mapped to port `5432`. The relevant statistical information about tag completeness is found in the table called
`cs_completeness`.

Every time you call this command, a new set of charging station points will be processed in `csc-process-db` and then
piped into `csc-prod-db` with a timestamp. This allows you to take periodic readings and see trends over time.

## Use

### API

The API has three endpoints and is accessible by default on port `8083`.

#### `/status` - Sanity check endpoint, a GET request just returns 200 to indicate that the server is online.

#### `/completeness` - Analyze the completeness of charging stations via a POST request.

Specify a study area with the `"studyArea"` key mapping to a valid GeoJSON to filter the results to a specific area.
Note that this GeoJSON must contain only one feature and it must be a Polygon or a MultiPolygon. Specify a time with
the `"timestamp"` key mapping to an ISO-compliant timestamp to only retrieve the set of results which were current in
the database at that timestamp.

Both of these keys are optional. Omitting `"studyArea"` will simply summarize the entire database. Omitting
`"timestamp"` will only summarize the most recent version of charging stations.

```json
{
  "studyArea":{
    "type":"FeatureCollection",
    "name":"ka-csc",
    "crs":{
      "type":"name",
      "properties":{
        "name":"urn:ogc:def:crs:OGC:1.3:CRS84"
      }
    },
    "features":[
      {
        "type":"Feature",
        "properties":{
          
        },
        "geometry":{
          "type":"Polygon",
          "coordinates":[
            [
              [
                8.393922325496273,
                48.991503115729685
              ],
              [
                8.394031307926372,
                49.029864931124415
              ],
              [
                8.448740487835906,
                49.029864931124415
              ],
              [
                8.448740487835906,
                48.986380941515044
              ],
              [
                8.448740487835906,
                48.986380941515044
              ],
              [
                8.393922325496273,
                48.991503115729685
              ]
            ]
          ]
        }
      }
    ]
  },
  "timestamp":"2023-09-30 00:00:00"
}
```

#### `/completeness_interval` - Analyze the completeness of charging stations over time via a POST request.

Specify a study area with the `"studyArea"` key mapping to a valid GeoJSON to filter the results to a specific area.
Note that this GeoJSON must contain only one feature and it must be a Polygon or a MultiPolygon. Specify a time interval
with the `"timestamps"` key as follows:

```json
{
  "start": <ISO-compliant timestamp>,
  "end": <ISO-compliant timestamp>
}
```

Both of these keys are optional. Omitting `"studyArea"` will simply summarize the entire database. Omitting
`"timestamps"` will only summarize all versions of the database.

In contrast to `/completeness`, this endpoint returns tag completeness results as arrays, and also returns a
`"timestamps"` key which corresponds to the timestamp for each array value in each tag result.

```json
{
  "studyArea":{
    "type":"FeatureCollection",
    "name":"ka-csc",
    "crs":{
      "type":"name",
      "properties":{
        "name":"urn:ogc:def:crs:OGC:1.3:CRS84"
      }
    },
    "features":[
      {
        "type":"Feature",
        "properties":{
          
        },
        "geometry":{
          "type":"Polygon",
          "coordinates":[
            [
              [
                8.393922325496273,
                48.991503115729685
              ],
              [
                8.394031307926372,
                49.029864931124415
              ],
              [
                8.448740487835906,
                49.029864931124415
              ],
              [
                8.448740487835906,
                48.986380941515044
              ],
              [
                8.448740487835906,
                48.986380941515044
              ],
              [
                8.393922325496273,
                48.991503115729685
              ]
            ]
          ]
        }
      }
    ]
  },
  "timestamps":{
    "start":"2023-09-30 00:00:00",
    "end":"2023-10-01 00:00:00"
  }
}
```

### UI

A web-based user interface can be found by default at port `8082`. It is based on Vue 3. You can draw a polygon on an
OpenLayers map and submit it as a request to the API, and it will return the result based on your input.

## Contributing

Just go for it. This project is not large enough, nor do I have the time or energy to warrant official contribution
guidelines. If you like the project and have an idea, make an issue. If you want to code directly on it, make a fork
and a PR. I'm happy for any support.

## Credits

* [Isaac Boates](https://github.com/iboates) - Started the project
* [Roman Karavia](https://github.com/romankaravia) - Helped a lot at the Geofabrik OSM Hackathon in 09.2023, mostly with
properly configuring the UI and getting it to communicate with the API
