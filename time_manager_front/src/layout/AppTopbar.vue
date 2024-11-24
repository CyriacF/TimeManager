<script setup>
import { ref, onMounted } from 'vue';
import { useLayout } from '@/layout/composables/layout';
import AppConfigurator from './AppConfigurator.vue';
import UserEdit from '@/components/user/UserEdit.vue';
import AvatarCustom from "@/components/avatar/AvatarCustom.vue";

const { onMenuToggle } = useLayout();
const isDialogVisible = ref(false);
const users = ref([]);

onMounted(() => {
onMenuToggle();
});
</script>


<template>
    <div class="layout-topbar">
        <div class="layout-topbar-logo-container">
            <router-link to="/" class="layout-topbar-logo">
                <img alt="logo" src="/logogotham.png"  />

                <span>GOTHAM T.M</span>
            </router-link>
        </div>

        <div class="layout-topbar-actions">
            <div class="layout-config-menu">

                <div class="relative">
                    <button
                        v-styleclass="{ selector: '@next', enterFromClass: 'hidden', enterActiveClass: 'animate-scalein', leaveToClass: 'hidden', leaveActiveClass: 'animate-fadeout', hideOnOutsideClick: true }"
                        type="button"
                        class="layout-topbar-action layout-topbar-action-highlight"
                    >
                        <i class="pi pi-palette"></i>
                    </button>
                    <AppConfigurator />
                </div>
            </div>

            <button
                class="layout-topbar-menu-button layout-topbar-action"
                v-styleclass="{ selector: '@next', enterFromClass: 'hidden', enterActiveClass: 'animate-scalein', leaveToClass: 'hidden', leaveActiveClass: 'animate-fadeout', hideOnOutsideClick: true }"
            >
                <i class="pi pi-ellipsis-v"></i>
            </button>

            <div class="layout-topbar-menu hidden lg:block">
                <div class="layout-topbar-menu-content">
                  <AvatarCustom size="small" @click="isDialogVisible = true"/>

                </div>
            </div>
        </div>
      <UserEdit :visible="isDialogVisible" @update:visible="isDialogVisible = $event" />
    </div>




</template>
