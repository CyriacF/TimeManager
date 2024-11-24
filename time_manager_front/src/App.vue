<script setup>
import { ref } from 'vue'
import {  RouterView } from 'vue-router'
import '@/assets/styles.scss';
import '@/assets/tailwind.css';
const isRoleChosen = ref(false)

function chooseRole() {
  isRoleChosen.value = true
}
</script>

<template>
  <main>

    <RouterView />
  </main>
</template>

<style scoped>
header {
  background-color: #f8f9fa;
  padding: 1rem;
}

nav a {
  margin-right: 1rem;
}

section {
  display: flex;
  flex-direction: column;
  align-items: center;
}

button {
  margin: 1rem;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  cursor: pointer;
}
</style>