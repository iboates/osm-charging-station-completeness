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
      style="position: absolute; top: 0"
      @click="clear"
      icon="mdi-shape-polygon-plus"
      size="large"
      color="primary"
      elevation="8"
    />
  </div>
</template>

<script>
import { fromLonLat } from "ol/proj";
import { GeoJSON } from "ol/format";

export default {
  data() {
    return {
      center: fromLonLat([8.4037, 49.0069]),
      zoom: 12,
      draw: true,
      modify: false,
    };
  },
  props: {
    features: Array,
  },
  methods: {
    clear() {
      this.draw = true;
      this.modify = false;
    },
    drawEnd(e) {
      this.draw = false;
      this.modify = true;
      // const geometry = e.feature.getGeometry();
      const geoJsonFormat = new GeoJSON({ featureProjection: "EPSG:3857" });
      const feature = geoJsonFormat.writeFeatureObject(e.feature);
      this.features.push(feature);
    },
  },
};
</script>
