import Request from './Request';

class Clocks {
  constructor() {
    this.request = new Request();
  }

  async createClockCurrentUser() {
    try {
      return await this.request.post('/api/myclock');
    } catch (error) {
      console.error('Error creating clock:', error);
      throw error
    }
  }
  async getClocks() {
    try {
      const clocks = await this.request.get(`/api/myclock`);
      return clocks;
    } catch (error) {
      console.error(`Error fetching clocks for user ${userId}:`, error);
      throw error;
    }
  }
  async getClock(id) {
    try {
      const clocks = await this.request.get(`/api/clocks/${id}`);
      return clocks;
    } catch (error) {
      console.error(`Error fetching clocks for user ${userId}:`, error);
      throw error;
    }
  }
async getLatestClock() {
    const clocks = await this.getClocks();
  return clocks[clocks.length - 1];
}
  async createClock(userId) {
    try {
      return await this.request.post(`/api/clocks/${userId}`);
    } catch (error) {
      console.error(`Error creating clock for user ${userId}:`, error);
      throw error;
    }
  }

  async createClockwithState(data) {
    try {
      return await this.request.post(`/api/clocks_with_state`, data);
    } catch (error) {
      console.error(`Error creating clock for user ${data.user_id}:`, error);
      throw error;
    }
  }
}

export default Clocks;