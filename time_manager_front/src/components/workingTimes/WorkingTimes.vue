<template>

  <div class="calendar">
    <vue-cal
      v-if="!loading"
      hide-view-selector
      view="week"
      locale="fr"
      :time-from="8 * 60 + 30"
      :time-to="19 * 60 + 30"
      :time-step="30"
      :hide-weekdays="[7]"
      :click-to-navigate="false"
      :dblclick-to-navigate="true"
      :events="calendarEvents"
      :min-event-width=100
    />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import VueCal from 'vue-cal';
import WorkingTime from '@/controller/WorkingTime';
import { useUserLogStore } from '@/store/UserLog.js';
import { storeToRefs } from 'pinia';
import 'vue-cal/dist/vuecal.css';
import './WorkingTimes.scss';
import { AbsenceType } from '@/controller/Absence';
import axios from "axios";

const userStore = useUserLogStore();
const { id: userId } = storeToRefs(userStore);

const workingtime = ref([]);
const calendarEvents = ref([]);
const loading = ref(true);

const workingtimeInstance = new WorkingTime();

async function fetchWorkingtime() {
  try {
    loading.value = true;
    workingtime.value = await workingtimeInstance.getWorkingtime(userId.value);

    if (Array.isArray(workingtime.value) && workingtime.value.length > 0) {
      updateCalendarEvents();
    } else {
      console.warn('Aucune donnée d\'event n\'est récupérée');
      calendarEvents.value = []; 
    }
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'event', error);
  } finally {
    loading.value = false;
  }
  await fetchHolidays();
}

async function fetchHolidays() {
  try {
    const response = await axios.get('https://calendrier.api.gouv.fr/jours-feries/metropole.json');
    const holidays = response.data;
    const holidayEvents = Object.keys(holidays).map(date => ({
      start: date,
      end: date,
      title: holidays[date],
      class: AbsenceType.FER
    }));
    calendarEvents.value = [...calendarEvents.value, ...holidayEvents];
  } catch (error) {
    console.error('Erreur lors de la récupération des jours fériés:', error);
  }
}


function updateCalendarEvents() {
  const workingtimeEvents = workingtime.value.map(time => {
    return {
      id: time.id,
      start: new Date(time.start),
      end: new Date(time.end),
      title: AbsenceType[time.category] || time.category,
      class: time.category,
    };
  });
  calendarEvents.value = [...workingtimeEvents];
}


watch(userId, (newUserId) => {
  if (newUserId) {
    fetchWorkingtime();
  } else {
    workingtime.value = [];
    calendarEvents.value = [];
  }
}, { immediate: true });

</script>
<style scoped>

</style>
