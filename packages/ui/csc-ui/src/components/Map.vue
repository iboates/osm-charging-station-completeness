<template>
  <VLayoutItem model-value size="88">
      <div class="ma-4">
          <VBtn
            @click="clear"
            icon="mdi-shape-polygon-plus"
            size="large"
            color="primary"
            elevation="8" />
      </div>
    </VLayoutItem>

  <ol-map
    :loadTilesWhileAnimating="true"
    :loadTilesWhileInteracting="true"
    style="height:95%"
  >
    <ol-view
      ref="view"
      :center="center"
      :rotation="rotation"
      :zoom="zoom"
      :projection="projection"
    />


    <ol-tile-layer>
      <ol-source-osm />
    </ol-tile-layer>

    <ol-vector-layer>
      <ol-source-vector
        ref="source"
      >
        <ol-interaction-draw
          v-if="draw"
          type="Polygon"
          @drawend="drawEnd"
        >
        </ol-interaction-draw>
        <ol-interaction-modify
          v-if="modify"
        >
          </ol-interaction-modify>
      </ol-source-vector>

      <ol-style>
        <ol-style-stroke color="red" :width="2"></ol-style-stroke>
      </ol-style>
    </ol-vector-layer>
  </ol-map>
</template>
  
  <script>
  import { ref, inject } from "vue";
  export default {
    setup() {
      const center = ref([49.0069, 8.4037]);
      const zoom = ref(8);
      const rotation = ref(0);
      const projection = ref("EPSG:4326");
      return {
        center,
        zoom,
        rotation,
      };
    },
    data() {
        return {
            draw: true,
            modify: false
        }
    },
    props: {
        features: null
    },
    methods: {
        clear() {
            this.draw = true;
            this.modify = false;
        },
        drawEnd(e) {
          this.draw = false;
          this.modify = true;
          let feature = e.feature.getGeometry().getCoordinates();
          console.log(e.feature);
          this.features.push(feature);
        },
    },
  };
  </script>
