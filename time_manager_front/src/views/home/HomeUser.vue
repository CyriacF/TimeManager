<template>
  <div class="home_container">
    <button @click="onMenuToggle">Toggle Menu</button>
    <AppSidebar />
    <h1>Home User</h1>
    <UserComponent />
    <GridHolder/>
    <TimelineDoc/>
  </div>


</template>

<script setup>
import UserComponent from '@/components/user/UserComponent.vue'
import GridHolder from "@/components/grid/GridHolder.vue";
import AppSidebar from "@/layout/AppSidebar.vue";
import { useLayout } from '@/layout/composables/layout';
const { onMenuToggle, toggleDarkMode, isDarkTheme } = useLayout();
</script>

<style scoped>
.home_user_container{
  width: 100%;
}
</style>