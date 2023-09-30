/**
 * main.js
 *
 * Bootstraps Vuetify and other plugins then mounts the App`
 */

// Components
import App from './App.vue'

// Composables
import { createApp } from 'vue'

// Plugins
import { registerPlugins } from '@/plugins'

import OpenLayersMap from "vue3-openlayers";
import "vue3-openlayers/dist/vue3-openlayers.css";

import axios from 'axios'
import VueAxios from 'vue-axios'


const app = createApp(App)
app.use(OpenLayersMap);

app.use(VueAxios, axios)


registerPlugins(app)

app.mount('#app')
