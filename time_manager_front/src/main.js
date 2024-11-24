import './library.scss'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { createPinia } from 'pinia';
import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import '@/assets/styles.scss';
import '@/assets/tailwind.css';
import ToastService from 'primevue/toastservice';
import Toast from 'primevue/toast';

const app = createApp(App)
const pinia = createPinia();
app.use(router)
app.use(pinia)

const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)").matches;
const isDarkMode = localStorage.getItem('isDarkMode') === 'true' || prefersDarkScheme;

app.use(PrimeVue, {
    theme: {
        preset:  Aura,
        options: {
            darkModeSelector: '.app-dark'
        }
    }
});
app.use(ToastService);
app.component('Toast', Toast);
app.mount('#app')


if (isDarkMode) {
    document.body.classList.add('night-mode');


} else {
    document.body.classList.remove('night-mode');
}