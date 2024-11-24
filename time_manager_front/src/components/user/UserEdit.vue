<script setup>
import {useUserLogStore} from "@/store/UserLog.js"; // Correction du chemin
import {defineProps, ref, computed, watch, onMounted} from 'vue';
import {storeToRefs} from 'pinia';
import Compressor from "compressorjs";
import User from "@/controller/User.js";
import {useToast} from 'primevue/usetoast';
import Dialog from 'primevue/dialog';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Toast from 'primevue/toast';
import AvatarCustom from "@/components/avatar/AvatarCustom.vue";
import Auth from "@/controller/Auth.js";
import Dropdown from 'primevue/dropdown'; // Pour les sélections de rôles
import DataTable from 'primevue/datatable'; // Pour afficher les membres de l'équipe
import Column from 'primevue/column';
import Manager from "@/controller/Manager.js"; // Colonnes de la DataTable

const UserStore = useUserLogStore();
const {
  username: storeUsername,
  email: storeEmail,
  id,
  is_manager,
  is_director,
  managed_teams
} = storeToRefs(UserStore);
const props = defineProps({
  visible: Boolean
});
const userController = new User();
const emit = defineEmits(['update:visible']);
const selectedFile = ref(null);
const auth = new Auth();
const toast = useToast();
let people = ref();
// Variables locales pour les champs de formulaire
const localUsername = ref(storeUsername.value);
const localEmail = ref(storeEmail.value);

// Variables locales pour le changement de mot de passe
const currentPassword = ref('');
const newPassword = ref('');
const confirmPassword = ref('');

// Variables locales pour ajouter un nouvel utilisateur
const newUserUsername = ref({});
const newUserEmail = ref({});
const newUserPassword = ref({});
const newUserRole = ref({});
const newUserTeam = ref({});
const AddUserTeam = ref({});
const availableEmployee = ref([]);
const roles = [
  {label: 'Utilisateur', value: 'user'},
  {label: 'Manager', value: 'manager'},
  {label: 'Director', value: 'director'}
];

// Variables pour la vue Teams
// Plus besoin de `teamMembers` séparé, utiliser `managed_teams` directement
const isLoadingTeam = ref(false);

// Ajout de la variable isAddingTeamMember pour gérer l'état de chargement
const isAddingTeamMember = ref({});

// Computed property pour filtrer les rôles disponibles en fonction du rôle de l'utilisateur actuel
const availableRoles = computed(() => {
  if (is_director.value) {
    return roles; // Tous les rôles disponibles
  } else if (is_manager.value) {
    return roles.filter(role => role.value !== 'director'); // Managers ne peuvent pas assigner le rôle Director
  } else {
    return []; // Aucun rôle disponible pour les autres utilisateurs
  }
});


  onMounted(async () => {
    const users = await userController.getUserAvailable();
    availableEmployee.value = users.map(user => ({
      label: user.username,
      value: user.id
    }));
    people.value = await userController.getUsers();
    console.log(people.value);
  });

const availableTeams = computed(() => {
  return managed_teams.value.map(team => ({label: team.name, value: team.id}));
});
const managerController = new Manager();
// Computed property pour vérifier si l'utilisateur peut gérer les équipes
const canManageTeam = computed(() => is_manager.value || is_director.value);
const canDeleteUser = computed(() => is_director.value);
// Fonction pour récupérer les données des équipes gérées depuis le store
const fetchTeamMembers = () => {
  // Puisque les données sont déjà dans le store, aucune action n'est nécessaire ici
  // Cette fonction peut être utilisée pour recharger les données si nécessaire
};

// Synchroniser les variables locales avec le store lorsque le dialogue est ouvert
watch(() => props.visible, (newVal) => {
  if (newVal) {
    localUsername.value = storeUsername.value;
    localEmail.value = storeEmail.value;
    // Réinitialiser les champs de mot de passe lorsque le dialogue est ouvert
    currentPassword.value = '';
    newPassword.value = '';
    confirmPassword.value = '';
    // Réinitialiser les champs d'ajout d'utilisateur
    newUserUsername.value = {};
    newUserEmail.value = {};
    newUserPassword.value = {};
    newUserRole.value = {};
    // Réinitialiser l'état de chargement pour les équipes
    isAddingTeamMember.value = {};
    // Si la vue actuelle est 'teams', nous utilisons les données du store
    if (currentView.value === 'teams') {
      fetchTeamMembers(); // Pas besoin d'appeler l'API
    }
  }
});

const onFileChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    if (file.size > 2 * 1024 * 1024) {
      // Compresser l'image si elle dépasse 2 Mo
      new Compressor(file, {
        quality: 0.6,
        success: (compressedResult) => {
          selectedFile.value = compressedResult;
        },
        error(err) {
          console.error("Erreur lors de la compression de l'image:", err);
          toast.add({
            severity: 'error',
            summary: 'Erreur',
            detail: 'Erreur lors de la compression de l\'image',
            life: 3000
          });
        },
      });
    } else {
      selectedFile.value = file;
    }
  }
};

const avatarCustom = ref(null); // Référence au composant AvatarCustom

const uploadImage = async () => {
  if (selectedFile.value) {
    try {
      await userController.uploadUserPhoto(
          id.value,
          selectedFile.value
      );
      toast.add({severity: 'success', summary: 'Succès', detail: 'Image téléversée avec succès', life: 3000});
      // Réinitialiser le fichier sélectionné
      selectedFile.value = null;
      UserStore.forceRefreshAvatar();
      await UserStore.updateData(); // Mettre à jour le store avec les nouvelles données
      currentView.value = 'menu';
    } catch (error) {
      console.error("Erreur lors du téléversement de l'image:", error);
      toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors du téléversement de l\'image', life: 3000});
    }
  }
};

// Gestion de la déconnexion
const handleLogout = () => {
  // Implémentez votre logique de déconnexion ici
  console.log('Déconnexion');
  // Par exemple, vider le store, rediriger, etc.
  auth.logout();

  emit('update:visible', false);
};

// Gestion des vues dans le dialogue
const currentView = ref('menu'); // 'menu', 'updateProfile', 'updateAvatar', 'changePassword', 'addUser', 'teams'

// Fonction pour changer la vue
const changeView = (view) => {
  currentView.value = view;
  emit('avatar', true);
  if (view === 'teams') {
    fetchTeamMembers(); // Pas besoin d'appeler l'API
  }
};

// Fonction pour revenir au menu principal
const backToMenu = () => {
  currentView.value = 'menu';
};

// Fonction pour sauvegarder le profil
const saveProfile = async () => {
  try {
    // Appeler le backend pour mettre à jour les informations de l'utilisateur
    await userController.updateMe(localUsername.value, localEmail.value);

    // Mettre à jour le store uniquement après une mise à jour réussie
    await UserStore.updateData();

    toast.add({severity: 'success', summary: 'Succès', detail: 'Profil mis à jour avec succès', life: 3000});
    emit('update:visible', false);
  } catch (error) {
    console.error("Erreur lors de la mise à jour du profil:", error);
    toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors de la mise à jour du profil', life: 3000});
  }
};

// Fonction pour changer le mot de passe
const changePassword = async () => {
  // Validation des champs
  if (!currentPassword.value || !newPassword.value || !confirmPassword.value) {
    toast.add({severity: 'warn', summary: 'Attention', detail: 'Tous les champs sont requis.', life: 3000});
    return;
  }

  if (newPassword.value !== confirmPassword.value) {
    toast.add({
      severity: 'error',
      summary: 'Erreur',
      detail: 'Les nouveaux mots de passe ne correspondent pas.',
      life: 3000
    });
    return;
  }

  try {
    // Appeler le backend pour changer le mot de passe
    await userController.changePassword(currentPassword.value, newPassword.value);

    toast.add({severity: 'success', summary: 'Succès', detail: 'Mot de passe mis à jour avec succès.', life: 3000});
    emit('update:visible', false);
  } catch (error) {
    console.error("Erreur lors du changement de mot de passe:", error);
    toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors du changement de mot de passe.', life: 3000});
  }
};

// Fonction pour ajouter un nouvel utilisateur
const addUser = async () => {
  // Validation des champs
  if (!newUserUsername.value || !newUserEmail.value || !newUserPassword.value || !newUserRole.value) {
    toast.add({severity: 'warn', summary: 'Attention', detail: 'Tous les champs sont requis.', life: 3000});
    return;
  }

  try {
    // Définir les flags is_manager et is_director en fonction du rôle sélectionné
    let is_manager_flag = false;
    let is_director_flag = false;

    if (newUserRole.value === 'manager') {
      is_manager_flag = true;
    } else if (newUserRole.value === 'director') {
      is_manager_flag = true; // Un director est aussi considéré comme manager si nécessaire
      is_director_flag = true;
    }

    // Construire les données utilisateur
    const userData = {
      user:{
      email: newUserEmail.value.value,
      password: newUserPassword.value.value,
      username: newUserUsername.value.value,
        team_id: newUserTeam.value.value,
      is_manager: is_manager_flag,
      is_director: is_director_flag
    }
    };

    // Appeler le backend pour ajouter le nouvel utilisateur
    await managerController.addUsers(userData);

    toast.add({severity: 'success', summary: 'Succès', detail: 'Nouvel utilisateur ajouté avec succès.', life: 3000});
    await UserStore.updateData(); // Mettre à jour le store avec les nouvelles données
    emit('update:visible', false);
  } catch (error) {
    console.error("Erreur lors de l'ajout de l'utilisateur:", error);
    toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors de l\'ajout de l\'utilisateur.', life: 3000});
  }
};

// Fonction pour ajouter un membre à l'équipe
const addTeamMember = async (team) => {
 if(!AddUserTeam.value){
   toast.add({severity: 'warn', summary: 'Attention', detail: 'Veuillez sélectionner un employée.', life: 3000});
   return;
 }
  isAddingTeamMember.value = true;
  const userData = {
    "user": {
      "team_id": team
    }
  };
  userController.updateUser(AddUserTeam.value.value, userData)
    .then(() => {
      toast.add({severity: 'success', summary: 'Succès', detail: 'Membre ajouté à l\'équipe avec succès.', life: 3000});
      // Mettre à jour les données du store pour refléter l'ajout
      UserStore.updateData();
      isAddingTeamMember.value = false;
      AddUserTeam.value = null;
    })
    .catch((error) => {
      console.error("Erreur lors de l'ajout du membre à l'équipe:", error);
      toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors de l\'ajout du membre à l\'équipe.', life: 3000});
      isAddingTeamMember.value = false;
    });
};

// Template pour afficher le rôle dans la DataTable
const roleTemplate = (rowData) => {
  console.log(rowData);
  if (rowData.is_director) {
    return 'Director';
  } else if (rowData.is_manager) {
    return 'Manager';
  } else {
    return 'Utilisateur';
  }
};
 const getRole = (rowData) => {
  if (rowData.is_director) {
    return 'Director';
  } else if (rowData.is_manager) {
    return 'Manager';
  } else {
    return 'Utilisateur';
  }
};

// Fonction pour éditer un utilisateur
const editUser = (userData) => {
  // Implémentez votre logique pour éditer un utilisateur ici
  console.log('Éditer l\'utilisateur:', userData);
};
const notMe =(data)=>{
  console.log(data);
  return data.id !== id.value;

}
// Fonction pour supprimer un utilisateur
const removeUser = (userData) => {
  userController.updateUser(userData.id)
    .then(() => {
      toast.add({severity: 'success', summary: 'Succès', detail: 'Utilisateur supprimé avec succès.', life: 3000});
      // Mettre à jour les données du store pour refléter la suppression
      UserStore.updateData();
    })
    .catch((error) => {
      console.error("Erreur lors de la suppression de l'utilisateur:", error);
      toast.add({severity: 'error', summary: 'Erreur', detail: 'Erreur lors de la suppression de l\'utilisateur.', life: 3000});
    });
};
// Définir le header du dialogue en fonction de la vue
const dialogHeader = computed(() => {
  switch (currentView.value) {
    case 'menu':
      return 'Paramètres Utilisateur';
    case 'updateProfile':
      return 'Mettre à Jour le Profil';
    case 'updateAvatar':
      return 'Mettre à Jour l\'Avatar';
    case 'changePassword':
      return 'Changer le Mot de Passe';
    case 'addUser':
      return 'Ajouter un Utilisateur';
    case 'teams':
      return 'Gestion des Équipes';
    case'people':
      return 'People';
    default:
      return 'Paramètres Utilisateur';
  }
});
</script>

<template>
  <Toast/>

  <Dialog
      v-model:visible="props.visible"
      modal
      :closable="false"
      :style="{ width: currentView === 'teams'||'people' ? '60rem' : '30rem' }"
      @hide="emit('update:visible', false)"
  >
    <template #header>
      <div class="flex justify-between items-center">
        <span class="text-xl font-semibold">
          {{ dialogHeader }}
        </span>
      </div>
    </template>

    <!-- Vue Menu -->
    <div v-if="currentView === 'menu'">
      <div class="flex flex-col gap-2">
        <Button
            label="Mettre à jour le profil"
            icon="pi pi-user-edit"
            class="w-full"
            @click="changeView('updateProfile')"
        />
        <Button
            label="Mettre à jour l'avatar"
            icon="pi pi-image"
            class="w-full"
            @click="changeView('updateAvatar')"
        />
        <Button
            v-if="canManageTeam"
            label="Gestion des Équipes"
            icon="pi pi-users"
            class="w-full"
            @click="changeView('teams')"
        />
        <Button
            label="People"
            icon="pi pi-users"
            class="w-full"
            @click="changeView('people')"
        />
        <Button
            v-if="canManageTeam"
            label="Ajouter un utilisateur"
            icon="pi pi-plus"
            class="w-full"
            @click="changeView('addUser')"
        />
        <Button
            label="Changer le mot de passe"
            icon="pi pi-lock"
            class="w-full"
            @click="changeView('changePassword')"
        />
        <Button
            label="Déconnexion"
            icon="pi pi-sign-out"
            class="w-full p-button-danger"
            @click="handleLogout"
        />
      </div>
    </div>

    <!-- Vue Mettre à Jour le Profil -->
    <div v-else-if="currentView === 'updateProfile'">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Mettez à jour vos informations.</span>
      <div class="flex items-center gap-4 mb-4">
        <label for="username" class="font-semibold w-24">Nom d'utilisateur</label>
        <InputText id="username" class="flex-auto" autocomplete="off" v-model="localUsername"/>
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="email" class="font-semibold w-24">Email</label>
        <InputText id="email" type="email" class="flex-auto" autocomplete="off" v-model="localEmail"/>
      </div>
    </div>

    <!-- Vue Mettre à Jour l'Avatar -->
    <div v-else-if="currentView === 'updateAvatar'">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Mettez à jour votre avatar.</span>
      <AvatarCustom ref="avatarCustom"/>
      <div class="flex items-center gap-4 mb-4">
        <input
            type="file"
            accept="image/*"
            @change="onFileChange"
            class="flex-auto"/>
      </div>
      <div v-if="selectedFile" class="flex items-center gap-4 mb-4">
        <span>Fichier sélectionné : {{ selectedFile.name }}</span>
      </div>
    </div>

    <!-- Vue Changer le Mot de Passe -->
    <div v-else-if="currentView === 'changePassword'">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Changez votre mot de passe.</span>
      <div class="flex items-center gap-4 mb-4">
        <label for="currentPassword" class="font-semibold w-24">Mot de passe actuel</label>
        <InputText id="currentPassword" type="password" class="flex-auto" autocomplete="off" v-model="currentPassword"/>
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="newPassword" class="font-semibold w-24">Nouveau mot de passe</label>
        <InputText id="newPassword" type="password" class="flex-auto" autocomplete="off" v-model="newPassword"/>
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="confirmPassword" class="font-semibold w-24">Confirmer le mot de passe</label>
        <InputText id="confirmPassword" type="password" class="flex-auto" autocomplete="off" v-model="confirmPassword"/>
      </div>
    </div>
    <!-- Vue Ajouter un Utilisateur -->
    <div v-else-if="currentView === 'addUser'">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Ajoutez un nouvel utilisateur.</span>
      <div class="flex items-center gap-4 mb-4">
        <label for="newUserUsername" class="font-semibold w-24">Nom d'utilisateur</label>
        <InputText
            id="newUserUsername"
            class="flex-auto"
            autocomplete="off"
            v-model="newUserUsername.value"
            placeholder="Nom d'utilisateur"
        />
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="newUserEmail" class="font-semibold w-24">Email</label>
        <InputText
            id="newUserEmail"
            type="email"
            class="flex-auto"
            autocomplete="off"
            v-model="newUserEmail.value"
            placeholder="Email"
        />
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="newUserPassword" class="font-semibold w-24">Mot de passe</label>
        <InputText
            id="newUserPassword"
            type="password"
            class="flex-auto"
            autocomplete="off"
            v-model="newUserPassword.value"
            placeholder="Mot de passe"
        />
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="newUserRole" class="font-semibold w-24">Equipe</label>
        <Dropdown
            id="newUserTeam"
            :options="availableTeams"
            optionLabel="label"
            optionValue="value"
            placeholder="Sélectionner une de vos équipes"
            v-model="newUserTeam.value"
            class="flex-auto"
        />
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label for="newUserRole" class="font-semibold w-24">Rôle</label>
        <Dropdown
            id="newUserRole"
            :options="availableRoles"
            optionLabel="label"
            optionValue="value"
            placeholder="Sélectionner un rôle"
            v-model="newUserRole.value"
            class="flex-auto"
        />
      </div>
    </div>
    <div v-else-if="currentView === 'people'" class="w-full">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Annuaire de l'entreprise</span>
      <div class="mb-6 w-full">
        <DataTable :value="people" :loading="isLoadingTeam" paginator rows="5" class="p-datatable-striped mb-4 w-full">
          <Column field="username" header="Nom d'utilisateur"></Column>
          <Column field="email" header="Email"></Column>
          <Column header="Rôle">
            <template #body="slotProps">
              {{ getRole(slotProps.data) }}
            </template>
          </Column>
          <Column field="team.name" header="Equipe"></Column>
          <Column  v-if="canDeleteUser" header="Actions" class="flex justify-center">
            <template #body="slotProps" >
              <div v-if="canDeleteUser && notMe(slotProps.data) " class="flex justify-center">
              <Button label="Supprimer" class="p-button-danger" @click="removeUser(slotProps.data)" /></div>
            </template>
          </Column>
        </DataTable>

      </div>
    </div>

    <!-- Vue Gestion des Équipes -->
    <div v-else-if="currentView === 'teams'">
      <span class="text-surface-500 dark:text-surface-400 block mb-4">Gestion des membres de vos équipes.</span>

      <!-- Liste des Équipes Gérées -->
      <div v-for="teamItem in managed_teams" :key="teamItem.id" class="mb-6">
        <h3 class="text-lg font-semibold mb-2">{{ teamItem.name }}</h3>

        <!-- Tableau des membres de l'équipe -->
        <DataTable :value="teamItem.users" :loading="isLoadingTeam" paginator rows="5" class="p-datatable-striped mb-4">
          <Column field="username" header="Nom d'utilisateur"></Column>
          <Column field="email" header="Email"></Column>
          <Column header="Rôle">
            <template #body="slotProps">
              {{ getRole(slotProps.data) }}
            </template>
          </Column>
          <!-- Nouvelle colonne pour les actions -->
          <Column header="Actions">
            <template #body="slotProps">
              <Button label="Supprimer de l'équipe" class="p-button-danger" @click="removeUser(slotProps.data)" />
            </template>
          </Column>
        </DataTable>



        <!-- Formulaire pour ajouter un membre à l'équipe -->
        <div class="flex items-center gap-4 mb-4">
          <label for="newUserUsername" class="font-semibold w-24">Employée</label>
          <Dropdown
              id="AddUserTeam"
              :options="availableEmployee"
              optionLabel="label"
              optionValue="value"
              placeholder="Sélectionner un employée libre"
              v-model="AddUserTeam.value"
              class="flex-auto"
          />

          <button
              class="p-button p-button-text"
              :disabled="isAddingTeamMember[teamItem.id]"
              @click="addTeamMember(teamItem.id)"
          > Ajouter à l'équipe</button>
        </div>
      </div>
    </div>

    <!-- Boutons d'Action -->
    <div class="flex justify-end gap-2 mt-4">
      <Button
          v-if="currentView !== 'menu' && currentView !== 'teams'"
          label="Retour"
          icon="pi pi-arrow-left"
          class="p-button-secondary"
          @click="backToMenu"
      />
      <Button
          v-if="currentView === 'menu'"
          label="Fermer"
          class="p-button-secondary"
          @click="emit('update:visible', false)"
      />
      <Button
          v-if=" currentView === 'teams'"
          label="Annuler"
          class="p-button-secondary"
          @click="backToMenu"
      />
      <Button
          v-if="currentView === 'updateProfile'"
          label="Enregistrer"
          icon="pi pi-save"
          class="p-button-success"
          @click="saveProfile"
      />
      <Button
          v-if="currentView === 'updateAvatar'"
          label="Téléverser"
          icon="pi pi-upload"
          class="p-button-success"
          :disabled="!selectedFile"
          @click="uploadImage"
      />
      <Button
          v-if="currentView === 'changePassword'"
          label="Changer le mot de passe"
          icon="pi pi-lock"
          class="p-button-success"
          @click="changePassword"
      />
      <Button
          v-if="currentView === 'addUser'"
          label="Ajouter l'utilisateur"
          icon="pi pi-plus"
          class="p-button-success"
          @click="addUser"
      />
      <!-- Bouton d'Ajout à l'Équipe est géré par les formulaires individuels -->
    </div>
  </Dialog>
</template>

<style scoped>
/* Ajoutez ici vos styles personnalisés si nécessaire */
</style>
