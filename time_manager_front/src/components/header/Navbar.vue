<template>
  <v-app-bar app flat class="navbar" sticky>
    <div class="nav-buttons">
      <v-btn text class="nav-btn" @click="scroll('home')">Home</v-btn>
      <v-btn text class="nav-btn" @click="scroll('about')">Working time</v-btn>
      <v-btn text class="nav-btn" @click="scroll('portfolio')">Teams</v-btn>
    </div>

    <v-spacer></v-spacer>

    <v-btn class="btn-account" @click="openModal">
      <i class="fas fa-user icon-account"></i>
      Account
    </v-btn>

    <span class="log-out">log out</span>

    <Modal :isOpen="isModalOpen" @close="closeModal" />
  </v-app-bar>
</template>

<script>
import './Navbar.scss'; 
import Modal from './modal/Modal.vue'; 

export default {
  components: {
    Modal
  },
  data() {
    return {
      isModalOpen: false
    };
  },
  methods: {
    scroll(refName) {
      const element = document.getElementById(refName);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    },
    openModal() {
      this.isModalOpen = true;
    },
    closeModal() {
      this.isModalOpen = false;
    }
  }
};
</script>

<style lang="scss">
@import "@/library.scss";
@import "./Navbar.scss";
</style>
