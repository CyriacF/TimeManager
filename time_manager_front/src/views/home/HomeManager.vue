<template>
  <div>
    <h1>Home Manager</h1>
    <UserComponent />
    <ChartManager />
  </div>
</template>

<script setup>
import UserComponent from '@/components/user/UserComponent.vue'
import ChartManager from "@/components/charts/ChartManager.vue";
</script>

<style scoped>
h1 {
  color: #333;
}
</style>