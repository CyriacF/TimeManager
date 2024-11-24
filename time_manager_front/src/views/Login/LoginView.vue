<script setup>
import { ref } from 'vue';

const email = ref('');
const password = ref('');
const checked = ref(false);
</script>

<template>
<div class="login-container">
<input-text v-model="email" label="Email" placeholder="Enter your email" />
<input-text v-model="password" label="Password" placeholder="Enter your password" />
</div>


</template>

<script>
import "./LoginView.scss";
</script>
