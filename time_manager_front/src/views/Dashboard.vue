<script setup>
import { useLayout } from '@/layout/composables/layout';
import { ProductService } from '@/service/ProductService';
import {computed, onMounted, ref, watch} from 'vue';
import GridHolder from "@/components/grid/GridHolder.vue";
import MainChartComponent from "@/components/charts/MainChartComponent.vue";
import ChartManager from "@/components/charts/ChartManager.vue";
import WorkingtimeComponent from "@/components/workingTime/WorkingtimeComponent.vue";
import {useUserLogStore} from "@/store/UserLog.js";
import Clocks from "@/controller/Clocks.js";
import WorkingTime from "@/controller/WorkingTime.js";
import AlertComponent from '@/components/alert/AlertComponent.vue';
import Avatar from 'primevue/avatar';
import AvatarGroup from 'primevue/avatargroup';
import Teams from "@/controller/Teams.js";
import TasksComponent from "@/components/tasks/TasksComponent.vue";
import User from "@/controller/User.js";
const { getPrimary, getSurface, isDarkTheme } = useLayout();

const products = ref(null);
const chartData = ref(null);
const chartOptions = ref(null);

const items = ref([
    { label: 'Add New', icon: 'pi pi-fw pi-plus' },
    { label: 'Remove', icon: 'pi pi-fw pi-trash' }
]);

const totalDays = ref(0);
const absence = ref(0);
const pourcentageAttendance = ref("100%");
const teamMembers = ref([]);
const avatars = ref({});
const userStore = useUserLogStore();
const isManager = computed(() => userStore.is_manager);

const initialCharts = computed(() => {
  if (userStore.is_director) {
    return ['MainChartComponent', 'AttendanceChart', 'NightChart'];
  } else if (userStore.is_manager) {
    return ['AttendanceChart', 'NightChart'];
  } else {
    return ['NightChart'];
  }
});

onMounted(async() => {
    ProductService.getProductsSmall().then((data) => (products.value = data));
    chartData.value = setChartData();
    chartOptions.value = setChartOptions();
  const clockController = new Clocks();
  const workingTimeController = new WorkingTime();
  const userController = new User();

    try {
      teamMembers.value = userStore.team.users;
      for (const member of teamMembers.value) {
        avatars.value[member.id] = await userController.getAvatar(member.id);
      }
      const workingtime = await workingTimeController.getWorkingtime(userStore.id);
      const clocks = await clockController.getClocks();
      const filteredWork = workingtime.filter(working => working.category !== 'Travail');
      const uniqueDays = new Set(clocks.map(clock => new Date(clock.time).toDateString()));
      const uniqueDaysAbs = new Set(filteredWork.map(work => new Date(work.time).toDateString()));
      totalDays.value = uniqueDays.size;
      absence.value = uniqueDaysAbs.size;
      pourcentageAttendance.value = `${((totalDays.value - absence.value) / totalDays.value) * 100}%`;
    } catch (error) {
      console.error('Error calculating total clocked days:', error);
      throw error;
    }
});

function setChartData() {
    const documentStyle = getComputedStyle(document.documentElement);

    return {
        labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        datasets: [
            {
                type: 'bar',
                label: 'Subscriptions',
                backgroundColor: documentStyle.getPropertyValue('--p-primary-400'),
                data: [4000, 10000, 15000, 4000],
                barThickness: 32
            },
            {
                type: 'bar',
                label: 'Advertising',
                backgroundColor: documentStyle.getPropertyValue('--p-primary-300'),
                data: [2100, 8400, 2400, 7500],
                barThickness: 32
            },
            {
                type: 'bar',
                label: 'Affiliate',
                backgroundColor: documentStyle.getPropertyValue('--p-primary-200'),
                data: [4100, 5200, 3400, 7400],
                borderRadius: {
                    topLeft: 8,
                    topRight: 8
                },
                borderSkipped: true,
                barThickness: 32
            }
        ]
    };
}

function setChartOptions() {
    const documentStyle = getComputedStyle(document.documentElement);
    const borderColor = documentStyle.getPropertyValue('--surface-border');
    const textMutedColor = documentStyle.getPropertyValue('--text-color-secondary');

    return {
        maintainAspectRatio: false,
        aspectRatio: 0.8,
        scales: {
            x: {
                stacked: true,
                ticks: {
                    color: textMutedColor
                },
                grid: {
                    color: 'transparent',
                    borderColor: 'transparent'
                }
            },
            y: {
                stacked: true,
                ticks: {
                    color: textMutedColor
                },
                grid: {
                    color: borderColor,
                    borderColor: 'transparent',
                    drawTicks: false
                }
            }
        }
    };
}

const formatCurrency = (value) => {
    return value.toLocaleString('en-US', { style: 'currency', currency: 'USD' });
};

watch([getPrimary, getSurface, isDarkTheme], () => {
    chartData.value = setChartData();
    chartOptions.value = setChartOptions();
});
</script>

<template>


    <div class="grid grid-cols-12 gap-8">
      <div class="col-span-12">
        <GridHolder/>
      </div>

        <div class="col-span-12 lg:col-span-6 xl:col-span-3">

            <div class="card mb-0 h-full">
                <div class="flex justify-between mb-4">
                    <div>
                        <span class="block text-muted-color font-medium mb-4">Total de jours faits</span>
                        <div class="text-surface-900 dark:text-surface-0 font-medium text-xl">{{ totalDays }}</div>
                    </div>
                    <div class="flex items-center justify-center bg-blue-100 dark:bg-blue-400/10 rounded-border" style="width: 2.5rem; height: 2.5rem">
                        <i class="pi pi-compass text-blue-500 !text-xl"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-span-12 lg:col-span-6 xl:col-span-3">
            <div class="card mb-0 h-full">
                <div class="flex justify-between mb-4">
                    <div>
                        <span class="block text-muted-color font-medium mb-4">Total d'absences</span>
                        <div class="text-surface-900 dark:text-surface-0 font-medium text-xl">{{ absence }}</div>
                    </div>
                    <div class="flex items-center justify-center bg-orange-100 dark:bg-orange-400/10 rounded-border" style="width: 2.5rem; height: 2.5rem">
                        <i class="pi pi-user-minus text-orange-500 !text-xl"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-span-12 lg:col-span-6 xl:col-span-3">
            <div class="card mb-0 h-full">
                <div class="flex justify-between mb-4">
                    <div>
                        <span class="block text-muted-color font-medium mb-4">Pourcentage de présence</span>
                        <div class="text-surface-900 dark:text-surface-0 font-medium text-xl">{{ pourcentageAttendance }}</div>
                    </div>
                    <div class="flex items-center justify-center bg-cyan-100 dark:bg-cyan-400/10 rounded-border" style="width: 2.5rem; height: 2.5rem">
                        <i class="pi pi-chart-bar text-cyan-500 !text-xl" style="margin: auto;"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-span-12 lg:col-span-6 xl:col-span-3">
            <div class="card mb-0 wid h-full">
                <div class="flex justify-between mb-4">
                    <div>
                        <span class="block text-muted-color font-medium mb-4">Membres de l'équipe</span>
                      <AvatarGroup>
                        <Avatar v-for="member in teamMembers" :key="member.id" :image="avatars[member.id]" size="large" shape="circle" :v-tooltip="member.username" />
                      </AvatarGroup>

                    </div>
                    <div class="flex items-center justify-center bg-purple-100 dark:bg-purple-400/10 rounded-border" style="width: 2.5rem; height: 2.5rem">
                        <i class="pi pi-comment text-purple-500 !text-xl"></i>
                    </div>
                </div>
            </div>
        </div>
      <div class="col-span-12 xl:col-span-6">
        <WorkingtimeComponent v-if="isManager"></WorkingtimeComponent>
        <div class="card">
        <div class="font-semibold text-xl mb-4">Tâches</div>
        <TasksComponent></TasksComponent>
        </div>
        </div>

        <div class="col-span-12 xl:col-span-6">
          <div class="card" v-if="isManager">
            <div class="font-semibold text-xl mb-4">Alertes</div>
            <AlertComponent></AlertComponent>
          </div>
            <div class="card">
                <div class="font-semibold text-xl mb-4">Graphiques</div>
              <ChartManager :initialCharts="initialCharts" />
            </div>

        </div>
    </div>
</template>
