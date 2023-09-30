<template>
  <v-app ref="app">
    <v-main>
      <Map :features="features" />
    </v-main>
    <v-footer app name="footer">
      <v-btn @click="submit">Submit</v-btn>
    </v-footer>
  </v-app>
</template>

<script>
import Map from "@/components/Map.vue";

export default {
  components: {
    Map,
  },
  data() {
    return {
      features: [],
    };
  },
  computed: {
    featuresAsGeoJson() {
      let geoJson = {
        type: "FeatureCollection",
        features: this.features,
      };

      return geoJson;
    },
  },
  methods: {
    submit() {
      const requestData = {
        studyArea: this.featuresAsGeoJson
      }
      this.axios
        .post("/api/completeness", requestData)
        .then((response) => {
          console.log(response.data);
        });
    },
  },
};
</script>
