// src/stores/UserLog.js
import { defineStore } from 'pinia';
import { ref, watch } from 'vue';
import User from '@/controller/User.js';

const userApi = new User();

export const useUserLogStore = defineStore('userLog', () => {
    // États utilisateur
    const id = ref(null);
    const username = ref('');
    const email = ref('');
    const is_manager = ref(false);
    const is_director = ref(false);
    const team = ref(null); // Object: { id, name, users, manager_id }
    const managed_teams = ref([]); // Array of teams
    const photoUrl = ref('');
    const avatarUpdateKey = ref(0);

    // État token séparé
    const token = ref('');

    // Charger les données utilisateur depuis localStorage lors de l'initialisation
    const storedUserData = JSON.parse(localStorage.getItem('userData'));
    if (storedUserData) {
        id.value = storedUserData.id;
        username.value = storedUserData.username;
        email.value = storedUserData.email;
        is_manager.value = storedUserData.is_manager;
        is_director.value = storedUserData.is_director;
        team.value = storedUserData.team;
        managed_teams.value = storedUserData.managed_teams;
        photoUrl.value = `http://localhost:4000/api/users/${storedUserData.id}/photo`;
    }

    // Charger le token depuis localStorage
    const storedToken = localStorage.getItem('token');
    if (storedToken) {
        token.value = storedToken;
    }

    // Observer les changements des données utilisateur et les enregistrer dans localStorage
    watch(
        () => ({
            id: id.value,
            username: username.value,
            email: email.value,
            is_manager: is_manager.value,
            is_director: is_director.value,
            team: team.value,
            managed_teams: managed_teams.value,
        }),
        (newUserData) => {
            localStorage.setItem('userData', JSON.stringify(newUserData));
        },
        { deep: true }
    );

    // Observer les changements du token et les enregistrer dans localStorage
    watch(
        () => token.value,
        (newToken) => {
            if (newToken) {
                localStorage.setItem('token', newToken);
            } else {
                localStorage.removeItem('token');
            }
        }
    );

    // Méthode pour définir les données utilisateur
    const setUserData = (userData) => {
        id.value = userData.id;
        username.value = userData.username;
        email.value = userData.email;
        is_manager.value = userData.is_manager;
        is_director.value = userData.is_director;
        team.value = userData.team;
        managed_teams.value = userData.managed_teams;
        photoUrl.value = `http://localhost:4000/api/users/${userData.id}/photo`;
    };

    // Méthode pour définir le token
    const setToken = (newToken) => {
        token.value = newToken;
    };

    const forceRefreshAvatar = () => {
        avatarUpdateKey.value++;
    };

    // Actions pour mettre à jour les informations utilisateur
    const setUsername = (newUsername) => {
        username.value = newUsername;
    };

    const setEmail = (newEmail) => {
        email.value = newEmail;
    };

    const setIsManager = (status) => {
        is_manager.value = status;
    };

    const setIsDirector = (status) => {
        is_director.value = status;
    };

    const setTeam = (teamData) => {
        team.value = teamData;
    };

    const setManagedTeams = (teams) => {
        managed_teams.value = teams;
    };

    // Action pour mettre à jour les données utilisateur depuis l'API
    const updateData = async () => {
        try {
            const data = await userApi.getCurrentUser();
            setUserData(data);
        } catch (error) {
            console.error('Failed to update user data:', error);
        }
    };

    const verifyToken = async () => {
        if (!token.value) {
            console.error('No token found');
            return false;
        }
        try {

           const data= await userApi.getCurrentUser();// Appel à GET /api/users/me
            setUserData(data);
            return true;
        } catch (error) {
            console.error('Token invalide ou expiré:', error);
            clearUserData();
            return false;
        }
    };

    // Méthode pour effacer les données utilisateur (par exemple lors de la déconnexion)
    const clearUserData = () => {
        id.value = null;
        username.value = '';
        email.value = '';
        is_manager.value = false;
        is_director.value = false;
        team.value = null;
        managed_teams.value = [];
        photoUrl.value = '';
        token.value = '';
        localStorage.removeItem('userData');
        localStorage.removeItem('token');
    };

    return {
        id,
        username,
        email,
        is_manager,
        is_director,
        team,
        managed_teams,
        photoUrl,
        token,
        avatarUpdateKey,
        setTeam,
        setManagedTeams,
        setToken,
        setUsername,
        setEmail,
        setIsManager,
        setIsDirector,
        verifyToken,
        setUserData,
        updateData,
        clearUserData,
        forceRefreshAvatar,
    };
});
