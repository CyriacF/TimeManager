<template>
  <div class="containerClock" :style="{ background: backgroundGradient }">
    <div class="header">
      <div class="top1">
        <div class="text-container" :style="{ color: textColor }">
          <span class="hello_text">Bonjour </span>
          <span class="name_text">{{ user.username }}</span>
        </div>
        <div class="weather-container">
          <img :src="iconWeather" alt="weather-icon" />
          <span :style="{ color: textColor }">{{ temperature }}°C</span>
        </div>
      </div>
      <span class="clocking_text" :style="{ color: textColor }">
        {{ clocking.status ? 'Vous êtes au bureau depuis' : 'Êtes-vous arrivé au bureau ?' }}
      </span>
      <span class="hours" :style="{ color: textColor }">
        {{ clocking.status ? formattedClockingTime : '' }}
      </span>
    </div>
    <div
        :class="[clocking.status ? 'clocking-off' : 'clocking-on', 'clock-button']"
        @click="toggleClocking"
    >
      <span>{{ clocking.status ? 'Partir' : 'Arrivée' }}</span>
      <HomeIcon v-if="clocking.status" class="icon" />
      <BriefcaseIcon v-else class="icon" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { format, differenceInHours } from 'date-fns';
import './Clocking.scss';
import { BriefcaseIcon, HomeIcon } from '@heroicons/vue/24/outline';
import Weather from '@/controller/Weather';
import Clocks from "@/controller/Clocks.js";
import { useUserLogStore } from "@/store/UserLog.js";
import { useToast } from "primevue/usetoast";

const user = useUserLogStore();
const username = ref(user.username);
const clockController = new Clocks();
const clocking = ref(false); // Initialisation en tant que booléen
const backgroundGradient = ref('');
const textColor = ref('#000000');
const weatherInstance = new Weather();
const userId = computed(() => user.id);
const toast = useToast();

const { weatherCondition, temperature, iconWeather } = await weatherInstance.getWeather("Lille");

watch(userId, async (newUserId, oldUserId) => {
  if (newUserId !== oldUserId) {
    await fetchClockingData();
  }
});

const weatherStyles = {
  Clear: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #f39c12 40%, #e67e22 100%)',
    textColor: '#ffffff'
  },
  Clouds: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #7f8c8d 40%, #2c3e50 100%)',
    textColor: '#ffffff'
  },
  Drizzle: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #5dade2 40%, #2e86c1 100%)',
    textColor: '#ffffff'
  },
  Mist: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #95a5a6 40%, #34495e 100%)',
    textColor: '#ffffff'
  },
  Rain: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #2980b9 40%, #2c3e50 100%)',
    textColor: '#ffffff'
  },
  Snow: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #d5d6dc 40%, #a6a9b6 100%)',
    textColor: '#ffffff'
  },
  Thunderstorm: {
    gradient: 'linear-gradient(180deg, var(--surface-card) 10%, #1f1c2c 40%, #2c3e50 100%)',
    textColor: '#ffffff'
  },

};

const setBackgroundTheme = (condition) => {
  const theme = weatherStyles[condition] || {
    gradient: 'linear-gradient(to right, #e0eafc, #cfdef3)',
    textColor: '#000000',
  };
  backgroundGradient.value = theme.gradient;
  textColor.value = theme.textColor;
};

const setClocking = (status) => {
  clocking.value = status;
};

const fetchClockingData = async () => {
  try {
    const lastClock = await clockController.getLatestClock();
    setClocking(lastClock);
  } catch (error) {
    console.error(
        'Erreur lors de la récupération de la dernière horloge pour l\'utilisateur',
        userId.value,
        ':',
        error
    );
  }
};

// Fonction pour ajouter une action à la file d'attente
function addToQueue(clockData) {
  let queue = JSON.parse(localStorage.getItem('clockQueue')) || [];
  queue.push(clockData);
  localStorage.setItem('clockQueue', JSON.stringify(queue));
}

// Fonction pour envoyer les requêtes en file d'attente
async function sendQueuedRequests() {
  let queue = JSON.parse(localStorage.getItem('clockQueue')) || [];
  while (queue.length > 0) {
    let clockData = queue[0];
    try {
      const newClock = await clockController.createClockwithState(clockData);
      queue.shift();
      localStorage.setItem('clockQueue', JSON.stringify(queue));
      setClocking(newClock);
    } catch (error) {
      console.error('Erreur lors de l\'envoi du pointage en file d\'attente:', error);
      break; // Arrêter si une erreur survient
    }
  }
}

// Écouteur pour détecter lorsque la connexion est rétablie
window.addEventListener('online', sendQueuedRequests);

const toggleClocking = async () => {
  const newStatus = !clocking.value.status;
  const clockData = {
    user_id: userId.value,
    time: new Date().toISOString(), // Format ISO standard
    status: newStatus ? 'true' : 'false',
    // Ajoutez d'autres informations nécessaires pour votre API
  };

  if (!navigator.onLine) {
    console.warn('API hors-ligne. Ajout du pointage à la file d\'attente.');
    toast.add({
      group: "center",
      severity: 'warn',
      summary: 'Attention',
      detail: 'Vous êtes actuellement hors-ligne. Votre pointage sera envoyé dès que la connexion sera rétablie.',
      life: 3000
    });
    addToQueue(clockData);
    setClocking({ status: newStatus, time: clockData.time }); // Mettre à jour l'état local
    return;
  }

  try {
    const newClock = await clockController.createClockwithState(clockData);
    setClocking(newClock);
  } catch (error) {
    console.error('Erreur lors du basculement de l\'horloge:', error);
    // En cas d'échec, ajouter à la file d'attente
    addToQueue(clockData);
    toast.add({
      group: "center",
      severity: 'error',
      summary: 'Erreur',
      detail: 'Une erreur est survenue lors du pointage. Votre pointage sera envoyé ultérieurement.',
      life: 3000
    });
  }
};

const formattedClockingTime = computed(() => {
  if (clocking.value && clocking.value.time) {
    return format(new Date(clocking.value.time), 'HH:mm');
  }
  return '';
});

const elapsedHours = computed(() => {
  if (clocking.value && clocking.value.time) {
    return differenceInHours(new Date(), new Date(clocking.value.time));
  }
  return 0;
});

onMounted(async () => {
  setBackgroundTheme(weatherCondition);
  try {
    const lastClock = await clockController.getLatestClock(userId.value);
    setClocking(lastClock);
  } catch (error) {
    console.error('Erreur lors de la récupération de la dernière horloge:', error);
  }

  // Envoyer les requêtes en attente au démarrage si en ligne
  if (navigator.onLine) {
    await sendQueuedRequests();
  }
});
</script>

<style scoped>
/* Votre CSS existant */
</style>
