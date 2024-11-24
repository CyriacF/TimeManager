<template>
  <div class="flex items-center justify-center">
    <Avatar
        :image="avatarUrl"
        :size="size"
        :shape="shape"
        :style="avatarStyle"
        :class="customClass"
        :key="avatarUpdateKey"
    />
  </div>
</template>

<script>
import {ref, computed, watch, onBeforeUnmount, onMounted} from 'vue';
import { useUserLogStore } from '@/store/UserLog.js';
import User from "@/controller/User.js";
import { getCurrentInstance } from 'vue';
import {storeToRefs} from "pinia"; // Import de l'instance User

export default {
  name: 'AvatarCustom',
  props: {
    size: {
      type: String,
      default: 'large', // Valeur par défaut
    },
    shape: {
      type: String,
      default: 'circle',
    },
    customClass: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const userStore = useUserLogStore();
    const instance = getCurrentInstance();

    const avatarUrl = ref('');
    const userId = computed(() => userStore.id);
    const username = computed(() => userStore.username);
    const userController = new User();
    const avatarUpdateKey = computed(() => userStore.avatarUpdateKey);
    const initials = computed(() => {
      if (username.value) {
        const names = username.value.split(' ');
        const initials = names.map(name => name.charAt(0).toUpperCase()).join('');
        return initials.slice(0, 2); // Limiter à 2 caractères
      }
      return "";
    });

    const avatarStyle = {
      cursor: 'pointer',
      width: props.size === 'small' ? '36px' : '100px',
      height: props.size === 'small' ? '36px' : '100px',
      backgroundColor: '#ece9fc',
      color: '#2a1261',

    };

    let blobUrl = null;

    const fetchAvatar = async () => {
      if (userId.value) {
        try {

          const fetchedUrl = await userController.getAvatar(userId.value);

          if (fetchedUrl) {
            avatarUrl.value = fetchedUrl;

          } else {
            avatarUrl.value = '';

          }
        } catch (error) {

          avatarUrl.value = '';
        }
      } else {
        avatarUrl.value = '';
      }
    };

    const handleUpdateAvatar = () => {
      fetchAvatar();

    };

    // Watcher pour l'ID utilisateur, pour re-fetch l'avatar lorsqu'il change
    watch(
        () =>  avatarUpdateKey,
        () => {
          fetchAvatar();
        },
        {immediate: true}
    );

    // Nettoyer le blob URL lors du démontage du composant pour éviter les fuites de mémoire
    onBeforeUnmount(() => {
      if (blobUrl) {
        URL.revokeObjectURL(blobUrl);
      }
    });
onMounted(() => {
  setTimeout(() => {
    fetchAvatar();
  }, 1000);
  });

    return {
      avatarUrl,
      initials,
      avatarStyle,
      avatarUpdateKey,
      size: props.size,
      shape: props.shape,
      customClass: props.customClass,
      handleUpdateAvatar
    };
  },
};
</script>

<style scoped>

</style>
