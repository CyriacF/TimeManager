<template>
  <canvas id="myChart"></canvas>


</template>

<script>
import Clocks from '@/controller/Clocks';
import User from '@/controller/User';
import Teams from '@/controller/Teams';
import { onMounted, ref } from 'vue';
import { Chart, registerables } from 'chart.js';

export default {
  name: 'MainChartComponent',
  setup() {
    const chartInstance = ref(null);
    const chartType = ref('line');

    const updateChartType = (type) => {
      chartType.value = type;
      if (chartInstance.value) {
        chartInstance.value.destroy();
        chartInstance.value = null;
      }
      createChart();
    };

    const documentStyle = getComputedStyle(document.documentElement);
    const borderColor = documentStyle.getPropertyValue('--surface-border');
    const textMutedColor = documentStyle.getPropertyValue('--text-color-secondary');

    const isToday = (date) => {
      const today = new Date();
      return date.getDate() === today.getDate() &&
          date.getMonth() === today.getMonth() &&
          date.getFullYear() === today.getFullYear();
    };

    const createChart = async () => {
      if (chartInstance.value) {
        chartInstance.value.destroy();
        chartInstance.value = null;
      }

      Chart.register(...registerables);

      try {
        const teamsInstance = new Teams();
        const userInstance = new User();
        const clocksInstance = new Clocks();

        // Récupérer les équipes
        const teams = await teamsInstance.getTeams();

        // Récupérer les utilisateurs
        const users = await userInstance.getUsers();

        const datasets = [];

        // Définir les heures de début et de fin
        const startHour = 0; // Vous pouvez ajuster l'heure de début si nécessaire
        const currentHour = new Date().getHours();

        // Générer les labels horaires jusqu'à l'heure actuelle
        const hourlyLabels = [];
        for (let hour = startHour; hour <= currentHour; hour++) {
          hourlyLabels.push(`${hour}:00`);
        }

        // Récupérer les horodatages pour chaque heure
        const hourTimestamps = hourlyLabels.map((label, index) => {
          const date = new Date();
          date.setHours(startHour + index, 0, 0, 0);
          return date.getTime();
        });

        // Récupérer les clocks pour tous les utilisateurs
        const userClocksMap = new Map();
        await Promise.all(users.map(async (user) => {
          if (user && user.id) {
            try {
              const clocks = await clocksInstance.getClock(user.id);
              // Trier les clocks par date
              clocks.sort((a, b) => new Date(a.time) - new Date(b.time));
              userClocksMap.set(user.id, clocks);
            } catch (error) {
              console.error(`Error fetching clocks for user ${user.id}`, error);
              userClocksMap.set(user.id, []);
            }
          }
        }));

        // Préparer le statut de chaque utilisateur à chaque heure
        const userStatusByHourMap = new Map();
        for (const user of users) {
          const clocks = userClocksMap.get(user.id) || [];

          // Déterminer le statut initial de l'utilisateur au début de la journée
          let inOffice = false;
          const startOfToday = new Date();
          startOfToday.setHours(0, 0, 0, 0);

          const clocksBeforeToday = clocks.filter(entry => new Date(entry.time) < startOfToday);
          if (clocksBeforeToday.length > 0) {
            const lastClockBeforeToday = clocksBeforeToday[clocksBeforeToday.length - 1];
            inOffice = lastClockBeforeToday.status;
          }

          // Filtrer les clocks d'aujourd'hui
          const clocksToday = clocks.filter(entry => new Date(entry.time) >= startOfToday);

          let clockIndex = 0;
          const statusByHour = [];

          for (let hourIndex = 0; hourIndex < hourlyLabels.length; hourIndex++) {
            const hourStart = new Date(startOfToday);
            hourStart.setHours(startHour + hourIndex, 0, 0, 0);
            const hourEnd = new Date(hourStart);
            hourEnd.setHours(hourStart.getHours() + 1);

            // Mettre à jour le statut en fonction des clocks jusqu'à cette heure
            while (clockIndex < clocksToday.length && new Date(clocksToday[clockIndex].time) < hourEnd) {
              const entry = clocksToday[clockIndex];
              inOffice = entry.status;
              clockIndex++;
            }

            statusByHour.push(inOffice);
          }

          userStatusByHourMap.set(user.id, statusByHour);
        }

        // Calculer les comptes pour chaque équipe et le total
        const totalCounts = new Array(hourlyLabels.length).fill(0);
        const currentUsersInOffice = new Set(); // Utiliser un Set pour éviter les doublons

        // Parcourir tous les utilisateurs pour calculer le total et la liste des utilisateurs au bureau
        for (let hourIndex = 0; hourIndex < hourlyLabels.length; hourIndex++) {
          for (const user of users) {
            const statusByHour = userStatusByHourMap.get(user.id);
            if (statusByHour && statusByHour[hourIndex]) {
              totalCounts[hourIndex]++;
              if (hourIndex === hourlyLabels.length - 1) {
                // Ajouter l'utilisateur à la liste s'il est au bureau à l'heure actuelle
                currentUsersInOffice.add(user.username);
              }
            }
          }
        }

        // Calculer les comptes pour chaque équipe
        for (const team of teams) {
          if (!team || !team.id) {
            console.error('Team is null or missing an ID:', team);
            continue;
          }

          const teamUsers = users.filter(user => user.team && user.team.id === team.id);

          const teamCounts = new Array(hourlyLabels.length).fill(0);

          for (let hourIndex = 0; hourIndex < hourlyLabels.length; hourIndex++) {
            for (const user of teamUsers) {
              const statusByHour = userStatusByHourMap.get(user.id);
              if (statusByHour && statusByHour[hourIndex]) {
                teamCounts[hourIndex]++;
              }
            }
          }

          datasets.push({
            label: `${team.name}`,
            data: teamCounts,
            borderColor: getRandomColor(),
            borderWidth: 3,
            fill: false,
            tension: 0.4
          });
        }

        // Ajouter le dataset pour le total
        datasets.push({
          label: 'Total',
          data: totalCounts,
          borderColor: '#FFFFFF',
          borderWidth: 3,
          fill: false,
          tension: 0.4
        });

        const ctx = document.getElementById('myChart').getContext('2d');
        chartInstance.value = new Chart(ctx, {
          type: chartType.value,
          data: {
            labels: hourlyLabels,
            datasets: datasets
          },
          options: {
            maintainAspectRatio: false,
            aspectRatio: 0.8,
            scales: {
              x: {
                stacked: false,
                ticks: {
                  color: textMutedColor
                },
                grid: {
                  color: 'transparent',
                  borderColor: 'transparent'
                }
              },
              y: {
                stacked: false,
                ticks: {
                  color: textMutedColor
                },
                grid: {
                  color: borderColor,
                  borderColor: 'transparent',
                  drawTicks: false
                }
              }
            },
            plugins: {
              title: {
                display: true,
                text: 'Nombre de personnes au bureau actuellement',
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
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    };

    onMounted(() => {
      createChart();
    });

    function getRandomColor() {
      const letters = '0123456789ABCDEF';
      let color = '#';
      for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    }

    return {
      updateChartType
    };
  }
};
</script>

<style scoped>
</style>
