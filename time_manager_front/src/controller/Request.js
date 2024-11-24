import axios from 'axios';
class Request {
    constructor() {
        // Création de l'instance d'axios pour les requêtes avec authentication
        this.client = axios.create({
            baseURL: "http://localhost:4000",
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${localStorage.getItem('token')}`,
            },

        });

        // Création de l'instance d'axios pour les requêtes d'images
        this.clientImage = axios.create({
            baseURL: "http://localhost:4000",
            headers: {
                Authorization: `Bearer ${localStorage.getItem('token')}`,
            },
        });

        this.client.interceptors.request.use(
            (config) => {
                const token = localStorage.getItem('token');
                if (token) {
                    config.headers.Authorization = `Bearer ${token}`;
                } else {
                    delete config.headers.Authorization;
                }
                return config;
            },
            (error) => {
                return Promise.reject(error);
            }
        );
    }

    async get(route) {
        try {
            const response = await this.client.get(route);
            return response.data;
        } catch (error) {
            console.error(`GET ${route} failed:`, error);
            throw error;
        }
    }



    async postImage(route, body = {}) {
        try {
            const response = await this.clientImage.post(route, body);
            return response.data;
        } catch (error) {
            console.error(`POST ${route} failed:`, error);
            throw error;
        }
    }

    async post(route, body = {}) {
        try {
            const response = await this.client.post(route, body);
            return response.data;
        } catch (error) {
            console.error(`POST ${route} failed:`, error);
            throw error;
        }
    }

    async patch(route, body = {}) {
        try {
            const response = await this.client.patch(route, body);
            return response.data;
        } catch (error) {
            console.error(`PATCH ${route} failed:`, error);
            throw error;
        }
    }

    async put(route, body = {}) {
        try {
            const response = await this.client.put(route, body);
            return response.data;
        } catch (error) {
            console.error(`PUT ${route} failed:`, error);
            throw error;
        }
    }

    async delete(route) {
        try {
            const response = await this.client.delete(route);
            return response.data;
        } catch (error) {
            console.error(`DELETE ${route} failed:`, error);
            throw error;
        }
    }
    async getImage(route, options = {}) {
        try {
            const response = await this.clientImage.get(route, { ...options });
            return response.data;
        } catch (error) {
            console.error(`GET Image ${route} failed:`, error);
            throw error;
        }
    }

    async pingAPI() {
        try {
            const response = await this.client.get('/auth/login');
            return response.data;
        } catch (error) {
            console.error('API ping failed:', error);
            throw error;
        }
    }
}

export default Request;
