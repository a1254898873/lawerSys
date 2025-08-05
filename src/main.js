//import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'

import axios from 'axios';

// 设置全局默认地址
axios.defaults.baseURL = 'http://localhost/v1';





const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')
