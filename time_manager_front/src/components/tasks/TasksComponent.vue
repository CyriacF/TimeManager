<template>
    <div class="tasks-container">
      <h3 class="tasks-title"><strong>Vous avez {{ tasks.length }} tâches à faire aujourd'hui :</strong></h3>
      <div v-if="tasks.length" class="">
        <ul class="tasks-list">
          <li v-for="task in tasks" :key="task.id">
            <div class="task-container h-full">
            <strong class="task-title">{{ task.title }}</strong>
            <span class="task-description">{{ task.description }}</span>
          </div>
          </li>
        </ul>
      </div>
      <div v-else>
        <p>Aucune tâche trouvée.</p>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, onMounted } from 'vue';
  import Tasks from '@/controller/Tasks.js';
  import { useUserLogStore } from '@/store/UserLog.js';
  import { storeToRefs } from 'pinia';
  
  const tasks = ref([]);
  const taskController = new Tasks();
  
  const userStore = useUserLogStore();
  const { id: userId } = storeToRefs(userStore);
  
  onMounted(async () => {
    console.log('userId:', userId.value);
    if (userId.value) {
      try {
        tasks.value = await taskController.getTasks(userId.value);
        console.log('tasks:', tasks.value);
      } catch (error) {
        console.error('Erreur lors de la récupération des tâches :', error);
      }
    }
  });
  </script>
  
  <style scoped>
  @import '@/library.scss';
  @import './TasksComponent.scss';
  </style>