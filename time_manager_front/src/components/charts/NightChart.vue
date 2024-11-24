<template>
  <div class="card" style="width: 100%">
    <canvas ref="nightChart"></canvas>
  </div>
</template>

<script setup>
import { useUserLogStore } from "@/store/UserLog.js";
import { ref, onMounted } from 'vue';
import { Chart, registerables } from 'chart.js';
import WorkingTime from '@/controller/WorkingTime';
import User from '@/controller/User';
import Teams from '@/controller/Teams';
const documentStyle = getComputedStyle(document.documentElement);
const textMutedColor = documentStyle.getPropertyValue('--text-color-secondary');

Chart.register(...registerables);

const nightChart = ref(null);
const currentUser = useUserLogStore();

const fetchNightShifts = async (sortByTeam = false) => {
  const userController = new User();
  const workingTimeController = new WorkingTime();
  const teamsController = new Teams();
  let users;

  if (currentUser.is_director) {
    users = await userController.getUsers();
  } else {
    const team = await teamsController.getTeam(currentUser.team.id);
    users = team.users;
  }

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 7);
  const endDate = new Date();

  const results = await Promise.all(users.map(async user => {
    console.log(user);
    const nightShifts = await workingTimeController.getNightWorkingtimeForWeek(user.id, startDate, endDate);
    return {
      name: user.username,
      nightShifts: nightShifts.length,
      teamId: user.team_id,
    };
  }));


  let sortedResults;
  if (sortByTeam) {
    sortedResults = results.sort((a, b) => a.teamId - b.teamId || b.nightShifts - a.nightShifts);
  } else {
    sortedResults = results.sort((a, b) => b.nightShifts - a.nightShifts);
  }
  const dataExists = results.some(result => result.nightShifts > 0);
  const labels = sortedResults.map(user => sortByTeam ? `${user.name}` : user.name);
  const data = sortedResults.map(user => user.nightShifts);

  new Chart(nightChart.value, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: "Nombre d'horaire de nuit",
        data: data,
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        y: {
          beginAtZero: true
        }
      },
      plugins: {
        title: {
          display: true,
          text: "Nombre d'horaires de nuit par utilisateur",
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

onMounted(() => fetchNightShifts(true)); // Pass true to sort by team, false for global
</script>

<style scoped>

</style>