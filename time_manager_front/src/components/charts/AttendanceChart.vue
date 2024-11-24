<script setup>
import { ref, onMounted } from 'vue';
import { Chart } from 'chart.js';
import Teams from '@/controller/Teams';
import WorkingTime from '@/controller/WorkingTime';
import Clocks from '@/controller/Clocks';
import { useUserLogStore } from '@/store/UserLog.js';

const chartInstance = ref(null);
const teams = new Teams();
const workingTime = new WorkingTime();
const clocks = new Clocks();
const userStore = useUserLogStore();
const documentStyle = getComputedStyle(document.documentElement);
const textMutedColor = documentStyle.getPropertyValue('--text-color-secondary');
const hasData = ref(false); // Indicateur de données présentes

const fetchTeamUsers = async (teamId) => {
  const team = await teams.getTeam(teamId);
  return team.users;
};

const fetchUserWorkingTimes = async (userId) => {
  return await workingTime.getWorkingtime(userId);
};

const fetchUserClocks = async (userId) => {
  return await clocks.getClocks(userId);
};
const calculateAttendancePercentage = (clocks, workingTimes) => {
  let totalWorkedHours = 0;
  let totalRequiredHours = 0;
  let isClockedIn = false;
  let lastClockInTime = null;

  // Calculer le total des heures requises
  workingTimes.forEach(workingTime => {
    const start = new Date(workingTime.start);
    const end = new Date(workingTime.end);
    const requiredHours = (end - start) / (1000 * 60 * 60);
    totalRequiredHours += requiredHours;
  });

  // Assurer que les pointages sont triés par heure
  clocks.sort((a, b) => new Date(a.time) - new Date(b.time));

  // Traiter les entrées de pointage
  clocks.forEach((clock, index) => {
    if (clock.status) {
      if (isClockedIn) {
        console.warn(`Déjà pointé à l'entrée à l'index ${index - 1}. Remplacement par une nouvelle entrée à l'index ${index}`);
      }
      isClockedIn = true;
      lastClockInTime = new Date(clock.time);
    } else {
      if (isClockedIn) {
        const endTime = new Date(clock.time);
        const workedHours = (endTime - lastClockInTime) / (1000 * 60 * 60);
        totalWorkedHours += workedHours;
        isClockedIn = false;
        lastClockInTime = null;
      } else {
        // Vous pouvez choisir d'ignorer cette sortie sans entrée correspondante
        console.warn(`Sortie sans entrée correspondante à l'index ${index}`);
        // Ou simplement continuer sans afficher le message d'avertissement
      }
    }
  });

  // Gérer le cas où l'utilisateur est toujours pointé à l'entrée
  if (isClockedIn) {
    console.warn(`L'utilisateur est toujours pointé à l'entrée sans entrée de sortie correspondante à la fin des données.`);
    // Optionnel : utiliser la fin du dernier temps de travail ou l'heure actuelle
    const lastWorkingTimeEnd = workingTimes.length > 0 ? new Date(workingTimes[workingTimes.length - 1].end) : new Date();
    const workedHours = (lastWorkingTimeEnd - lastClockInTime) / (1000 * 60 * 60);
    totalWorkedHours += workedHours;
  }

  // Calculer le pourcentage d'assiduité en évitant la division par zéro
  let attendancePercentage = 0;
  if (totalRequiredHours === 0) {
    // Si aucune heure requise, considérer l'assiduité comme 100%
    attendancePercentage = 0;
  } else {
    attendancePercentage = (totalWorkedHours / totalRequiredHours) * 100;
  }

  return attendancePercentage;
};

const createChart = async () => {
  const teamId = userStore.team.id;
  const teamUsers = await fetchTeamUsers(teamId);

  const labels = [];
  const data = [];

  for (const user of teamUsers) {
    const workingTimes = await fetchUserWorkingTimes(user.id);
    const clocks = await fetchUserClocks(user.id);

    let attendancePercentage = calculateAttendancePercentage(clocks, workingTimes);
    if(attendancePercentage > 100) {
      attendancePercentage = 100;
    }

    labels.push(user.username);
    data.push(attendancePercentage.toFixed(2)); // Arrondir à deux décimales
  }
  hasData.value = data.some(value => value > 0); // Vérification de données non nulles

  const ctx = document.getElementById('attendanceChart').getContext('2d');
  chartInstance.value = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Pourcentage d\'assiduité',
        data,
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        y: {
          beginAtZero: true,
          max: 100,
          ticks: {
            callback: function (value) {
              return value + '%';
            }
          }
        }
      },
      plugins: {
        title: {
          display: true,
          text: "Pourcentage d'assiduité par utilisateur",
          color: textMutedColor,
          font: {
            size: 16
          }
        },
        legend: {
          labels: {
            color: textMutedColor
          }
        }
      }
    }
  });
};

onMounted(() => {
  createChart();
});

</script>

<template>
  <div class="card" style="width: 100%">
    <canvas id="attendanceChart"></canvas>
  </div>
</template>

<style scoped>
/* Ajoutez vos styles ici si nécessaire */
</style>
