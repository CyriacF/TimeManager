import Request from './Request';
import Teams from "@/controller/Teams.js";

class User {
  constructor() {
    this.request = new Request();
    this.user = null;
  }


async updateMe(username, email, isManager = false, teamId = null) {
    const userData= {
        user: {
            username: username,
            email: email,
        }
    };
    try {
        const updatedUser = await this.request.put('/api/me', userData);
        this.user = updatedUser;
        return updatedUser;
    } catch (error) {
        console.error('Error updating user:', error);
        throw error;
    }


}
  async updateUser(userId,userData) {
    try {
      const updatedUser = await this.request.put(`/api/users/${userId}`, userData);
      this.user = updatedUser;
      return updatedUser;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
  }

  async getUser(userId) {
    try {
      const user = await this.request.get(`/api/users/${userId}`);
      this.user = user;
      return user;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  }


  async getUsers() {
    try {
      const users = await this.request.get('/api/users');
      return users;
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  }
    async getUserAvailable() {
        try {
            const users = await this.getUsers();
            const rslt = users.filter(user => user.team === null);
            return rslt;
        } catch (error) {
            console.error("Error fetching available users:", error);
            throw error;
        }
    }
  async deleteUser(userId) {
    try {
      await this.request.delete(`/api/users/${userId}`);
      this.user = null;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }


  async getAvatar(userId) {
    try {
      const response = await this.request.getImage(`/api/users/${userId}/photo`, { responseType: 'blob' });
      if (response) {

       return URL.createObjectURL(response);
      }
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'avatar:', error);

    }
  }

async changePassword(currentPassword, password) {

    const passwordData = {
      current_password: currentPassword,
      new_password: password
    };
    try {
        return await this.request.put('/api/change_password', passwordData);
    } catch (error) {
        console.error('Error changing password:', error);
        throw error;
    }

}
  async getUserPhotoUrl(userId) {

    return `http://localhost:4000/api/users/${userId}/photo`;
  }

  async uploadUserPhoto(userId, photoFile) {
    try {
      const formData = new FormData();
      formData.append('photo', photoFile);

      const response = await this.request.postImage(`/api/users/${userId}/photo`, formData);
      return response;
    } catch (error) {
      console.error('Error uploading user photo:', error);
      throw error;
    }
  }
    async addTeamMember(userId, teamId) {
        try {
            const response = await this.request.put(`/api/users/${userId}`,
                {
                    user: {
                        team_id: teamId
                    }
                }
            );
            return response.data;
        } catch (error) {
            throw error.response ? error.response.data : new Error('Erreur inconnue');
        }
    }
  async getCurrentUser() {
    try {
      const user = await this.request.get('/api/me');
      this.user = user;
      return user;
    } catch (error) {
      console.error('Error fetching current user:', error);
      throw error;
    }
  }

}

export default User;