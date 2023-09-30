<template>
  <div style="position: relative; height: 100%">
    <ol-map
      :loadTilesWhileAnimating="true"
      :loadTilesWhileInteracting="true"
      style="height: 100%"
    >
      <ol-view ref="view" :center="center" :zoom="zoom" />

      <ol-tile-layer>
        <ol-source-osm />
      </ol-tile-layer>

      <ol-vector-layer>
        <ol-source-vector ref="source">
          <ol-interaction-draw v-if="draw" type="Polygon" @drawend="drawEnd">
          </ol-interaction-draw>
          <ol-interaction-modify v-if="modify"> </ol-interaction-modify>
        </ol-source-vector>

        <ol-style>
          <ol-style-stroke color="red" :width="2"></ol-style-stroke>
        </ol-style>
      </ol-vector-layer>
    </ol-map>

    <v-btn
      class="ma-4"
      style="position: absolute; bottom: 0"
      @click="clear"
      icon="mdi-shape-polygon-plus"
      size="large"
      color="primary"
      elevation="8"
    />
  </div>
</template>

<script>
import Feature from "ol/Feature";
import { GeoJSON } from "ol/format";
import { MultiPolygon } from "ol/geom";
import { fromLonLat } from "ol/proj";

export default {
  data() {
    return {
      multiPolygon: new MultiPolygon([]),
      center: fromLonLat([8.4037, 49.0069]),
      zoom: 12,
      draw: false,
      modify: false,
    };
  },
  methods: {
    clear() {
      this.draw = true;
      this.modify = false;
    },
    drawEnd(e) {
      this.draw = false;
      this.modify = true;
      this.multiPolygon.appendPolygon(e.feature.getGeometry());
      const geoJsonFormat = new GeoJSON({ featureProjection: "EPSG:3857" });
      const feature = geoJsonFormat.writeFeatureObject(new Feature(this.multiPolygon));
      this.$emit("update:feature", feature);
    },
  },
};
</script>
