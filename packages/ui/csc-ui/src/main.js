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


const app = createApp(App)
app.use(OpenLayersMap);

registerPlugins(app)

app.mount('#app')
