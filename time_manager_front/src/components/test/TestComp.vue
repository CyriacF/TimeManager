<template>
  <div>
    <Button label="Ouvrir le dialogue" @click="openDialog" />

    <Dialog
        v-model:visible="showDialog"
        modal
        header="Sélectionner un utilisateur"
        @update:visible="onDialogClose"
    >
      <span class="text-surface-500 dark:text-surface-400 block mb-8">
        Mettez à jour les informations de l'utilisateur.
      </span>
      <div class="flex items-center gap-4 mb-4">
        <label for="user-select" class="font-semibold w-24">Utilisateur</label>
        <Dropdown
            id="user-select"
            :options="users"
            optionLabel="username"
            optionValue="id"
            placeholder="-- Sélectionnez un utilisateur --"
            v-model="selectedUserId"
            @change="onUserChange"
            class="flex-auto"
        />
      </div>
      <div class="flex items-center gap-4 mb-4">
        <label class="font-semibold w-24">Avatar</label>
        <div class="avatar-section">
        <AvatarCustom/>
        </div>
      </div>
      <div class="flex items-center gap-4 mb-8">
        <label class="font-semibold w-24">Image</label>
        <input
            type="file"
            accept="image/*"
            @change="onFileChange"
            class="flex-auto"
        />
      </div>
      <div class="flex justify-end gap-2">
        <Button
            type="button"
            label="Annuler"
            severity="secondary"
            @click="closeDialog"
        />
        <Button
            type="button"
            label="Téléverser l'image"
            @click="uploadImage"
            :disabled="!selectedFile || !selectedUserId"
        />
      </div>
    </Dialog>
  </div>
</template>

<script>
import User from "@/controller/User.js";
import Compressor from "compressorjs";
import { ref, computed } from "vue";
import AvatarCustom from "@/components/avatar/AvatarCustom.vue";
import { useUserLogStore } from "@/store/UserLog.js";
import { storeToRefs } from 'pinia';

export default {
  name: "UserDialog",
  components: {
    AvatarCustom

  },
  setup() {
    const { username, email ,id} = storeToRefs(User);
    const showDialog = ref(false);
    const users = ref([]);
    const selectedUserId = ref(id);
    const userAvatarUrl = ref("");
    const selectedFile = ref(null);
    const userController = new User();
    const selectedUser =User;

    const openDialog = () => {
      showDialog.value = true;
      fetchUsers();
    };

    const closeDialog = () => {
      showDialog.value = false;
      resetData();
    };

    const onDialogClose = () => {
      resetData();
    };

    const fetchUsers = async () => {
      try {
        users.value = await userController.getUsers();
      } catch (error) {
        console.error(
            "Erreur lors de la récupération des utilisateurs:",
            error
        );
      }
    };

    const onUserChange = async () => {
      if (selectedUserId.value) {
        try {
          // Obtenir l'URL de la photo de l'utilisateur
          const photoUrl = await userController.getUserPhotoUrl(
              selectedUserId.value
          );

          // Vérifier si l'image existe
          const response = await fetch(photoUrl, { method: "HEAD" });
          if (response.ok) {
            userAvatarUrl.value = photoUrl;
          } else {
            userAvatarUrl.value = ""; // L'image n'existe pas
          }

          // Récupérer l'utilisateur sélectionné pour obtenir ses initiales
          selectedUser.value = users.value.find(
              (user) => user.id === selectedUserId.value
          );
        } catch (error) {
          console.error("Erreur lors de la récupération de l'avatar:", error);
          userAvatarUrl.value = ""; // Réinitialiser l'URL de l'avatar en cas d'erreur
        }
      }
    };

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
            },
          });
        } else {
          selectedFile.value = file;
        }
      }
    };

    const uploadImage = async () => {
      if (selectedFile.value && selectedUserId.value) {
        try {
          await userController.uploadUserPhoto(
              selectedUserId.value,
              selectedFile.value
          );
          alert("Image téléversée avec succès");
          // Rafraîchir l'avatar
          await onUserChange();
          // Réinitialiser le fichier sélectionné
          selectedFile.value = null;
        } catch (error) {
          console.error("Erreur lors du téléversement de l'image:", error);
        }
      }
    };

    const resetData = () => {
      selectedUserId.value = "";
      userAvatarUrl.value = "";
      selectedFile.value = null;
      selectedUser.value = null;
    };

    // Calculer les initiales de l'utilisateur
    const userInitials = computed(() => {
      if (selectedUser.value && selectedUser.value.username) {
        const names = selectedUser.value.username.split(" ");
        const initials = names
            .map((name) => name.charAt(0).toUpperCase())
            .join("");
        return initials.slice(0, 2); // Limiter à 2 caractères
      }
      return "";
    });

    // Style personnalisé pour l'Avatar sans image
    const avatarStyle = {
      backgroundColor: "#ece9fc",
      color: "#2a1261",
    };

    return {
      showDialog,
      users,
      selectedUserId,
      userAvatarUrl,
      selectedFile,
      openDialog,
      closeDialog,
      onDialogClose,
      onUserChange,
      onFileChange,
      uploadImage,
      userInitials,
      avatarStyle,
    };
  },
};
</script>

<style scoped>
.avatar-section {
  margin-top: 10px;
}
.avatar {
  width: 100px;
  height: 100px;
  object-fit: cover;
}
</style>
