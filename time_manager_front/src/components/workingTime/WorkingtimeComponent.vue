<template>
  <div class="card">
    <div class="font-semibold text-xl mb-4">Gestion Collaborateur</div>
    <div>
      <div class="user-info" v-if="!selectedUser">

          <blockquote class="user-quote">
            <p>
              Bonjour {{ user.username }},
              <span v-if="user.is_manager">
        <span v-if="teamUsers">
          vous êtes manager, cliquez sur l'un de vos collaborateurs pour gérer son emploi du temps.
        </span>
        <span v-else>
          vous êtes manager, mais cet espace est disponible uniquement si vous avez des collaborateurs.
        </span>
      </span>
              <span v-else>
        vous pouvez consulter votre emploi du temps sur le calendrier.
      </span>
            </p>
          </blockquote>

        <div v-if="user.is_manager && teamUsers.length" class="team-members">
          <h3>Membres de l'équipe :</h3>
          <Button class=" p-button p-component"  v-for="teamUser in teamUsers" :key="teamUser.id" @click="selectUser(teamUser)">
            <p>{{ teamUser.username }}</p>
          </Button>

        </div>
      </div>
      <div v-else>
        <button class="return-button" @click="deselectUser">Retour</button>
        <h3 class="highlight-text">Temps de travail pour {{ selectedUser.username }}</h3>
        <Button class="p-button p-component mb-2" @click="showAddEventForm = !showAddEventForm">Ajouter un événement</Button>
        <div v-if="showAddEventForm" class="add-event-form">
          <form @submit.prevent="addEvent">
            <label>
              Heure de début :
              <input type="datetime-local" v-model="newEvent.start" required />
            </label>
            <label>
              Heure de fin :
              <input type="datetime-local" v-model="newEvent.end" required />
            </label>
            <button type="submit">Ajouter</button>
          </form>
        </div>
        <div class="calendar">
        <vue-cal
            v-if="!loading"
            locale="fr"
            :events="calendarEvents"
            :time="true"
            default-view="day"
            :time-from="7 * 60"
            :disable-views="['years', 'year']"
            hide-weekends
            :show-all-day-events="['short', true, false][showAllDayEvents]"
            :events-on-month-view="[true, 'short'][shortEventsOnMonthView * 1]"
            @event-click="onEventClick"
        />
        </div>
        <div v-if="selectedEvent">
          <button class="btn btn-add-event" @click="deleteEvent(selectedEvent)">
            Supprimer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import { format } from 'date-fns';
import User from '@/controller/User';
import Teams from '@/controller/Teams';
import WorkingTime from '@/controller/WorkingTime.js';
import VueCal from 'vue-cal';
import 'vue-cal/dist/vuecal.css';
import { useToast } from 'primevue/usetoast';
import { useUserLogStore } from '@/store/UserLog.js';
import { storeToRefs } from 'pinia';
import axios from "axios";
import { AbsenceType } from '@/controller/Absence';
import "./WorkingtimeComponent.scss";
const userStore = useUserLogStore();
const { id: userId, username } = storeToRefs(userStore);

const user = ref({});
const teamUsers = ref([]);
const selectedUser = ref(null);
const workingtime = ref([]);
const calendarEvents = ref([]);
const showAllDayEvents = ref(0);
const shortEventsOnMonthView = ref(false);
const loading = ref(true);
const showAddEventForm = ref(false);
const newEvent = ref({ start: '', end: '' });
const selectedEvent = ref(null);

const userInstance = new User();
const teamsInstance = new Teams();
const workingtimeInstance = new WorkingTime();

const toast = useToast();

watch(userId, (newId) => {
  if (newId) {
    fetchUser();
  } else {
    user.value = {};
    teamUsers.value = [];
  }
}, { immediate: true });

async function fetchUser() {
  if (userId.value) {
    try {
      user.value = await userInstance.getUser(userId.value);
      if (user.value.is_manager && user.value.team.id) {
        const team = await fetchTeam(user.value.team.id);
        teamUsers.value = team.users;
      } else {
        toast.add({ group: "bottomLeft", severity: 'warn', summary: 'Erreur', detail: `${username.value} n\'est pas manager ou n\'a pas d\'équipe`, life: 3000 });
      }
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'utilisateur:', error);
    }
  } else {
  }
}

async function fetchTeam(teamId) {
  try {
    const team = await teamsInstance.getTeam(teamId);
    return team;
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'équipe:', error);
    return { users: [] };
  }
}

function selectUser(teamUser) {
  selectedUser.value = teamUser;
}

function deselectUser() {
  selectedUser.value = null;
}

watch(selectedUser, (newSelectedUser) => {
  if (newSelectedUser) {
    fetchWorkingtime(newSelectedUser.id);
  } else {
    workingtime.value = [];
    calendarEvents.value = [];
    loading.value = true;
  }
});

async function fetchWorkingtime(userId) {
  try {
    workingtime.value = await workingtimeInstance.getWorkingtime(userId);
    updateCalendarEvents();
    await fetchHolidays();
  } catch (error) {
    console.error('Erreur lors de la récupération du temps de travail:', error);
  }
}

function updateCalendarEvents() {
  const workingtimeEvents = workingtime.value.map(time => ({
    id: time.id,
    start: format(new Date(time.start), 'yyyy-MM-dd HH:mm'),
    end: format(new Date(time.end), 'yyyy-MM-dd HH:mm'),
    title: AbsenceType[time.category] || time.category,
    class: time.category // Ajout de la classe pour les événements de workingtime
  }));
  calendarEvents.value = [...workingtimeEvents];
  loading.value = false;
}

function formatDateToISO(dateString) {
  const date = new Date(dateString);
  return date.toISOString().split('.')[0] + 'Z';
}

function isOverlapping(newStart, newEnd) {
  return workingtime.value.some(wt => {
    const existingStart = new Date(wt.start);
    const existingEnd = new Date(wt.end);
    return (newStart < existingEnd && newEnd > existingStart);
  });
}

async function addEvent() {
  try {
    const startTime = formatDateToISO(newEvent.value.start);
    const endTime = formatDateToISO(newEvent.value.end);

    const newStart = new Date(startTime);
    const newEnd = new Date(endTime);

    if (isOverlapping(newStart, newEnd)) {
      toast.add({ severity: 'error', summary: 'Erreur', detail: 'Le créneau de travail se superpose avec un créneau existant.', life: 3000 });
      return;
    }

    const workingtimeData = {
      working_time: {
        start: startTime,
        end: endTime
      }
    };

    await workingtimeInstance.createWorkingtime(selectedUser.value.id, workingtimeData);
    await fetchWorkingtime(selectedUser.value.id);
    showAddEventForm.value = false;
    newEvent.value = { start: '', end: '' };
  } catch (error) {
    console.error('Erreur lors de l\'ajout de l\'événement:', error);
  }
}

function onEventClick(event) {
  selectedEvent.value = event;
}

async function deleteEvent(event) {
  try {
    console.log('Suppression de l\'événement:', event);
    await workingtimeInstance.deleteWorkingtime(event.id);
    await fetchWorkingtime(selectedUser.value.id);
    selectedEvent.value = null;
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'événement:', error);
  }
}

async function fetchHolidays() {
  try {
    const response = await axios.get('https://calendrier.api.gouv.fr/jours-feries/metropole.json');
    const holidays = response.data;
    const holidayEvents = Object.keys(holidays).map(date => ({
      start: date,
      end: date,
      title: holidays[date],
      class: 'holiday'
    }));
    calendarEvents.value = [...calendarEvents.value, ...holidayEvents];
  } catch (error) {
    console.error('Erreur lors de la récupération des jours fériés:', error);
  }
}
</script>

<style scoped>
@import '@/library.scss';
@import './WorkingtimeComponent.scss';
</style>