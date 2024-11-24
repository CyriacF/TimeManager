// src/router/index.js
import AppLayout from '@/layout/AppLayout.vue';
import { createRouter, createWebHistory } from 'vue-router';
import { useUserLogStore } from '@/store/UserLog.js';
import Login from '@/views/pages/auth/Login.vue';
import NotFound from '@/views/pages/NotFound.vue';
import AccessDenied from '@/views/pages/auth/Access.vue';
import ErrorPage from '@/views/pages/auth/Error.vue';


const routes = [
  {
    path: '/',
    component: AppLayout,
    meta: { requiresAuth: true }, // Routes protégées
    children: [
      {
        path: '/',
        name: 'dashboard',
        component: () => import('@/views/Dashboard.vue'),
        meta: { requiresAuth: true }, // Optionnel si le parent a déjà meta
      },
      // Ajoutez d'autres routes enfants protégées ici
    ],
  },

  {
    path: '/pages/notfound',
    name: 'notfound',
    component: NotFound,
    meta: { requiresAuth: false }, // Routes publiques
  },

  {
    path: '/auth/login',
    name: 'login',
    component: Login,
    meta: { requiresAuth: false },
  },
  {
    path: '/auth/access',
    name: 'accessDenied',
    component: AccessDenied,
    meta: { requiresAuth: false },
  },
  {
    path: '/auth/error',
    name: 'error',
    component: ErrorPage,
    meta: { requiresAuth: false },
  },
  // Route catch-all pour les pages non trouvées
  {
    path: '/:pathMatch(.*)*',
    redirect: '/pages/notfound',
    meta: { requiresAuth: false },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// Route Guard Global
router.beforeEach(async (to, from, next) => {
  const userStore = useUserLogStore();

  // Routes qui ne nécessitent pas d'authentification
  if (!to.meta.requiresAuth) {
    return next();
  }

  // Vérifier la validité du token en appelant le backend
  const isValid = await userStore.verifyToken();

  if (isValid) {
    return next();
  } else {
    userStore.clearUserData();
    return next({ name: 'login' });
  }
});

export default router;
