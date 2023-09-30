<template>
  <v-app>
    <v-main>
      <Map :features=features />
      <v-btn @click="submit">Submit</v-btn>
    </v-main>
  </v-app>

</template>

<!-- <script setup>
  // import HelloWorld from '@/components/HelloWorld.vue'
  import Map from '@/components/Map.vue'
</script> -->

<script>
  import Map from '@/components/Map.vue';
  
  export default {
    components: {
      Map
    },
    data() {
        return {
          features: []
        }
    },
    computed: {
      featuresAsGeoJson() {

        let geoJson = {
          "type": "FeatureCollection",
          "crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:OGC:1.3:CRS84" } },
          "features": []
        }

        for (let feature of this.features) {
          geoJson.features.push(
            { "type": "Feature", "properties": { }, "geometry": { "type": "Polygon", "coordinates": [ feature ] } },
          )
        }

        return geoJson

      }
    },
    methods: {
        submit() {
            console.log(JSON.stringify(this.featuresAsGeoJson));
            this.axios
              .post("/api/completeness", this.featuresAsGeoJson)
              .then((response) => {
                console.log(response.data)
              });
              }
    }
  }
</script>