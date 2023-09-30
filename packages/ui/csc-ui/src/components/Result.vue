<template>
  <v-table>
    <thead>
      <tr>
        <th class="text-left">Attribute</th>
        <th class="text-left">missing</th>
        <th class="text-left">present</th>
        <th class="text-left">present_in_parent</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="([attribute, values], index) in items" :key="index">
        <td>{{ attribute }}</td>
        <td>{{ values.missing }}</td>
        <td>{{ values.present }}</td>
        <td>{{ values.present_in_parent }}</td>
      </tr>
    </tbody>
  </v-table>
</template>

<script>
export default {
  props: {
    completeness: Object,
  },
  computed: {
    items() {
      return Object.entries(this.completeness);
    },
  },
};
</script>
