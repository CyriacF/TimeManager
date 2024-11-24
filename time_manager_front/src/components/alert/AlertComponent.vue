<template>
  <div class="widget">
    <div>
      <div class="user-info" v-if="!selectedUser">
        <blockquote class="user-quote" v-if="user.is_manager">
          <span v-if="teamUsers">
            Bonjour {{ user.username }}, cliquez sur l'un de vos collaborateurs pour visualiser ses alertes.
          </span>
          <span v-else>
            Cet espace est disponible seulement si vous avez des collaborateurs.Il vous permet de voir rapidement les alertes
          </span>
        </blockquote>
        <div v-if="teamUsers.length" class="team-members">
          <h3>Membres de l'équipe :</h3>

          <Button class=" p-button p-component"  v-for="teamUser in teamUsers" :key="teamUser.id" @click="selectUser(teamUser)">
            <p>{{ teamUser.username }}</p><div class="alert-bubble" v-if="teamUser.alertsCount">{{ teamUser.alertsCount }}</div>
          </Button>
        </div>
      </div>
      <div v-else>
        <button class="return-button" @click="deselectUser">Retour</button>
        <div class="alert-container">
          <div v-if="alerts.length">
            <h3>Alertes pour {{ selectedUser.username }} :</h3>
            <div class="alert-block" v-for="alert in alerts" :key="alert.date">
              <p><strong>Alerte le :</strong> {{ formatDate(alert.date) }}</p>
              <p><strong>Période réellement travaillée :</strong> {{ Math.round(alert.actualDuration) }} minutes</p>
              <p><strong>Temps de travail obligatoire :</strong> {{ Math.round(alert.expectedDuration) }} minutes</p>
              <p><strong>Différence :</strong> {{ Math.round(alert.difference) }} minutes</p>
            </div>
          </div>
          <div v-else>
            <p>Aucune alerte trouvée.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


<script setup>
import { ref, watch } from 'vue';
import User from '@/controller/User';
import Teams from '@/controller/Teams';
import Clocks from '@/controller/Clocks';
import WorkingTime from '@/controller/WorkingTime'; // Import du contrôleur WorkingTime
import { useUserLogStore } from '@/store/UserLog.js';
import { storeToRefs } from 'pinia';

const user = ref({});
let teamUsers = ref([]);
const selectedUser = ref(null);
const alerts = ref([]);

const userInstance = new User();
const teamsInstance = new Teams();
const clocksInstance = new Clocks();
const workingtimeInstance = new WorkingTime(); // Initialisation de l'instance WorkingTime

const userStore = useUserLogStore();
const { id: userId } = storeToRefs(userStore);

// Observer les changements de userId
watch(userId, (newId) => {
  if (newId) {
 teamUsers = ref([]);
    fetchUser();
  } else {
    user.value = {};
    teamUsers.value = [];
  }
}, { immediate: true });

async function fetchUser() {
  if (userId.value) {
    try {
      user.value = await userInstance.getCurrentUser();
      if (user.value.is_manager && user.value.team.id) {
        const team = await fetchTeam(user.value.team.id);
        teamUsers.value = await Promise.all(
            team.users.map(async (teamUser) => {
              const alertsCount = await fetchAlertsCount(teamUser.id);
              return { ...teamUser, alertsCount };
            })
        );
      } else {

      }
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'utilisateur :', error);
    }
  }
}

async function fetchTeam(teamId) {
  try {
    return await teamsInstance.getTeam(teamId);
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'équipe :', error);
    return { users: [] };
  }
}

async function fetchAlerts(userId) {
  try {
    const clocks = await clocksInstance.getClocks(userId);
    const workingtimes = await workingtimeInstance.getWorkingtime(userId);
    return calculateAlerts(clocks, workingtimes, 15); // Calcul des alertes avec un seuil de 15 minutes
  } catch (error) {
    console.error('Erreur lors de la récupération des alertes :', error);
    return [];
  }
}

async function fetchAlertsCount(userId) {
  try {
    const clocks = await clocksInstance.getClocks(userId);
    const workingtimes = await workingtimeInstance.getWorkingtime(userId);
    const alerts = calculateAlerts(clocks, workingtimes, 15);
    return alerts.length;
  } catch (error) {
    console.error('Erreur lors de la récupération du nombre d\'alertes :', error);
    return 0;
  }
}

function calculateAlerts(clocks, workingtimes, threshold) {
  const alertsList = [];
  const today = new Date().setHours(0, 0, 0, 0); // Définir aujourd'hui à minuit

  workingtimes.forEach((workingtime) => {
    const workingDate = new Date(workingtime.start).setHours(0, 0, 0, 0);

    if (workingDate < today) {
      const dayClocks = clocks.filter(
        (clock) => new Date(clock.time).setHours(0, 0, 0, 0) === workingDate
      );

      let actualDuration = 0;
      let clockInTime = null;

      dayClocks.forEach((clock) => {
        if (clock.status === true) {
          clockInTime = new Date(clock.time);
        } else if (clock.status === false && clockInTime) {
          actualDuration += (new Date(clock.time) - clockInTime) / (1000 * 60); // en minutes
          clockInTime = null;
        }
      });

      const expectedDuration = (new Date(workingtime.end) - new Date(workingtime.start)) / (1000 * 60); // en minutes
      const difference = Math.abs(actualDuration - expectedDuration);

      if (difference > threshold) {
        alertsList.push({
          date: new Date(workingtime.start).toDateString(),
          actualDuration,
          expectedDuration,
          difference,
        });
      }
    }
  });

  return alertsList;
}

function selectUser(teamUser) {
  selectedUser.value = teamUser;
  fetchAlerts(teamUser.id).then((fetchedAlerts) => {
    alerts.value = fetchedAlerts;
  });
}

function deselectUser() {
  selectedUser.value = null;
  alerts.value = [];
}
function formatDate(date) {
  return new Date(date).toLocaleDateString('fr-FR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}



</script>

  
  <style scoped>
  @import '@/library.scss';
  @import './AlertComponent.scss';
  </style>