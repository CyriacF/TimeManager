import Request from './Request';

class Tasks {
  constructor() {
    this.request = new Request();
  }

  async getTasks(userID) {
    try {
      const response = await this.request.get(`/api/users/${userID}/tasks`);
      console.log('Response from API:', response); // Ajoutez ceci
      return response;
    } catch (error) {
      console.error('Erreur lors de la récupération des tâches :', error);
      throw error;
    }
  }
}

export default Tasks;