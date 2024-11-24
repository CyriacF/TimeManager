<template>
  <div class="widget">
    <div v-if="!user.id">
      <label>
        User ID:
        <input v-model="userId" placeholder="Enter user ID" />
      </label>
      <button @click="fetchUser">Fetch User</button>
    </div>
    <div v-else>
      <div class="user-info">
        <p><strong>Nom:</strong> {{ user.username }}</p>
        <p><strong>Email:</strong> {{ user.email }}</p>
        <p><strong>Team:</strong> {{ teamName }}</p>
        <p v-if="!user.is_manager"><strong>Manager:</strong> {{ managerName }}</p>
        <span v-if="user.is_manager" class="badge">Manager</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import User from '@/controller/User';
import Teams from '@/controller/Teams';

const userId = ref('');
const user = ref({});
const teamName = ref('');
const managerName = ref('');
const userInstance = new User();
const teamsInstance = new Teams();

async function fetchUser() {
  if (userId.value) {
    try {
      user.value = await userInstance.getCurrentUser();
      if (user.value.team_id) {
        teamName.value = await fetchTeamName(user.value.team_id);
        managerName.value = await fetchManagerName(user.value.team_id);
      }
    } catch (error) {
      console.error('Error fetching user:', error);
    }
  }
}

async function fetchTeamName(teamId) {
  try {
    const team = await teamsInstance.getTeam(teamId);
    return team.name; // Assurez-vous que l'objet team a une propriété name
  } catch (error) {
    console.error('Error fetching team name:', error);
    return '';
  }
}

async function fetchManagerName(teamId) {
  try {
    const team = await teamsInstance.getTeam(teamId);
    if (team.manager_id) {
      const manager = await userInstance.getUser(team.manager_id);
      return manager.username; // Assurez-vous que l'objet manager a une propriété username
    }
    return '';
  } catch (error) {
    console.error('Error fetching manager name:', error);
    return '';
  }
}
</script>

<style scoped>
@import '@/library.scss';
@import './UserComponent.scss';
</style>