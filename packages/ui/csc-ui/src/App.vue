<template>
  <v-app>
    <v-main>
      <Map @update:feature="feature = $event" />
    </v-main>
    <v-footer app style="max-height: 50%; overflow: auto; align-items: initial;">
      <Result v-if="completeness" :completeness="completeness" />
      <v-btn v-else @click="submit">Submit</v-btn>
    </v-footer>
  </v-app>
</template>

<script>
import Map from "@/components/Map.vue";
import Result from "@/components/Result.vue";

export default {
  components: {
    Map,
    Result,
  },
  data() {
    return {
      completeness: null,
      feature: null,
    };
  },
  computed: {
    featureCollection() {
      if (!this.feature) {
        return null
      }
      return {
        type: "FeatureCollection",
        features: [this.feature],
      };
    },
  },
  methods: {
    submit() {
      const requestData = {
        studyArea: this.featureCollection,
      };
      this.axios.post("/api/completeness", requestData).then((response) => {
        this.completeness = response.data;
      });
    },
  },
};
</script>
