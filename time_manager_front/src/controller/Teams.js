import Request from './Request';

class Teams {
  constructor() {
    this.request = new Request();
  }

  async getTeams() {
    try {
      const teams = await this.request.get('/api/teams');
      return teams;
    } catch (error) {
      console.error('Error fetching teams:', error);
      throw error;
    }
  }

  async getTeam(id) {
    try {
      const team = await this.request.get(`/api/teams/${id}`);
      return team;
    } catch (error) {
      console.error('Error fetching team:', error);
      throw error;
    }
  }

  async createTeam(managerId, name,color) {
    const teamData = {
      team: {
        manager_id: managerId,
        name: name,
        color:color
      }
    };

    try {
      const newTeam = await this.request.post('/api/teams', teamData);
      return newTeam;
    } catch (error) {
      console.error('Error creating team:', error);
      throw error;
    }
  }

  async updateTeam(id, name) {
    const teamData = {
      team: {
        name: name
      }
    };

    try {
      const updatedTeam = await this.request.put(`/api/teams/${id}`, teamData);
      return updatedTeam;
    } catch (error) {
      console.error('Error updating team:', error);
      throw error;
    }
  }

  async deleteTeam(id) {
    try {
      await this.request.delete(`/api/teams/${id}`);
    } catch (error) {
      console.error('Error deleting team:', error);
      throw error;
    }
  }
}

export default Teams;