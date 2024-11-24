<script setup>
import FloatingConfigurator from '@/components/FloatingConfigurator.vue';
import {useRouter} from "vue-router";
import { ref } from 'vue';
import Auth from '@/controller/Auth.js';
import { useToast } from 'primevue/usetoast';
const email = ref('');
const password = ref('');
const checked = ref(false);
const auth = new Auth();
const router = useRouter();
const toast = useToast()
const handleLogin = async () => {
  try {
    const user = await auth.login(email.value, password.value);
    if (user) {
      await router.push("/");

      toast.add({ group: "center", severity: 'success', summary: 'Réussi', detail: 'Connexion avec succès !', life: 3000 });
      toast.add({ group: "center", severity: 'contrast', summary: 'Réussi', detail: user, life: 3000 });
    }
  } catch (error) {
    if (error.response && error.response.status === 429) {
      // Gestion du code 429 (Too Many Requests)
      toast.add({ group: "center", severity: 'error', summary: 'Erreur', detail: 'Trop de tentatives de connexion. Veuillez réessayer plus tard', life: 3000 });
    } else {
      // Gestion des autres erreurs (par exemple, email ou mot de passe incorrects)
      toast.add({ group: "center", severity: 'error', summary: 'Erreur', detail: 'La connexion a échoué : Email ou mot de passe non valide', life: 3000 });
    }
  }
};
</script>

<template>
    <FloatingConfigurator />
  <Toast group="center" position="bottom-right"></Toast>

  <div class="bg-surface-50 dark:bg-surface-950 flex items-center justify-center min-h-screen min-w-[100vw] overflow-hidden">
        <div class="flex flex-col items-center justify-center">
            <div style="border-radius: 56px; padding: 0.3rem; background: linear-gradient(180deg, var(--primary-color) 10%, rgba(33, 150, 243, 0) 30%)">
                <div class="w-full bg-surface-0 dark:bg-surface-900 py-20 px-8 sm:px-20" style="border-radius: 53px">
                    <div class="flex justify-center items-center align-content-center flex-col mb-8">

                      <img src="/logogotham.png" alt="logo" class=" mb-4" style="width: 9rem"/>
                        <div class="text-surface-900 dark:text-surface-0 text-3xl font-medium mb-4">Bienvenue sur Gotham T.M!</div>
                        <span class="text-muted-color font-medium">Se connecter pour continuer</span>
                    </div>

                    <div>
                        <label for="email1" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Email</label>
                        <InputText id="email1" type="text" placeholder="Email address" class="w-full md:w-[30rem] mb-8" v-model="email" />

                        <label for="password1" class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">Mot de passe</label>
                        <Password id="password1" v-model="password" placeholder="Password" :toggleMask="true" class="mb-4" fluid :feedback="false"></Password>

                        <div class="flex items-center justify-between mt-2 mb-8 gap-8">

                            <span class="font-medium no-underline ml-2 text-right cursor-pointer text-primary">Mot de passe oublié ?</span>
                        </div>
                        <Button label="Se connecter" class="w-full"  @click="handleLogin"></Button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.pi-eye {
    transform: scale(1.6);
    margin-right: 1rem;
}

.pi-eye-slash {
    transform: scale(1.6);
    margin-right: 1rem;
}
</style>
