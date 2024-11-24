import Request from './Request';
import Teams from "@/controller/Teams.js";

class Manager {
    constructor() {
        this.request = new Request();
        this.user = null;
    }

    async addUsers(userData)  {
        try {
            const newUser = await this.request.post('auth/register', userData);
            this.user = newUser;
            return newUser;
        } catch (error) {
            console.error('Error adding user:', error);
            throw error;
        }
    }


}
export default Manager;