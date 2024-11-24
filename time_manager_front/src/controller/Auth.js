import Request from './Request';
import { useUserLogStore } from '@/store/UserLog.js'; // Assurez-vous d'importer votre store Pinia
import { useRouter } from 'vue-router';

class Auth {
    constructor() {
        this.request = new Request();
        this.user = null;
         this.userStore = useUserLogStore();
       this.router = useRouter();

    }

    async login(email, password) {
        try {
            const response = await this.request.post('/auth/login', { email, password });
            this.user = response;

            console.log('Login successful:', this.user);
            // Stocker les données utilisateur dans le store Pinia et dans localStorage
            // Stocker les données utilisateur et le token dans le store Pinia et localStorage
            this.userStore.setUserData({
                id: response.user.id,
                username: response.user.username,
                email: response.user.email,
                is_manager: response.user.is_manager,
                is_director: response.user.is_director,
                team_id: response.user.team_id,
            });
            this.userStore.setToken(response.token);
            return this.user;

        } catch (error) {
            console.error('Login failed:', error);
            throw error;
        }
    }

    async logout() {
        // Supprimer les données utilisateur du store Pinia et du localStorage
     this.userStore.clearUserData();
        this.userStore.setToken(null);
        // Rediriger vers la page de connexion
        this.router.push('/auth/login');
    }
}
export default Auth;