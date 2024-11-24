import Request from './Request';

class WorkingTime {
  constructor() {
    this.request = new Request();
  }

  async getWorkingtime(userId) {
    try {
      const workingtime = await this.request.get(`/api/workingtime/${userId}`);
      return workingtime;
    } catch (error) {
      console.error(`Error fetching working time for user ${userId}:`, error);
      throw error;
    }
  }

  async getNightWorkingtimeForWeek(userId, startDate, endDate) {
    try {
      const workingtimes = await this.getWorkingtime(userId);
      const nightWorkingTimes = workingtimes.filter(wt => {
        const start = new Date(wt.start);
        const end = new Date(wt.end);

        // Check if the working time is within the specified week
        if (start >= startDate && end <= endDate) {
          // Check if any part of the working time overlaps with night hours (22:00 - 06:00)
          const startHour = start.getHours();
          const endHour = end.getHours();
          const isNightShift = (startHour >= 22 || startHour < 6) || (endHour >= 22 || endHour < 6);
          return isNightShift;
        }
        return false;
      });
      return nightWorkingTimes;
    } catch (error) {
      console.error(`Error fetching night working time for user ${userId}:`, error);
      throw error;
    }
  }

  async createWorkingtime(userId, workingtimeData) {
    try {
      const newWorkingtime = await this.request.post(`/api/workingtime/${userId}`, workingtimeData);
      return newWorkingtime;
    } catch (error) {
      throw error;
    }
  }

  async updateWorkingtime(userId, startTime, endTime) {
    const workingtimeData = {
      workingtime: {
        start: startTime,
        end: endTime
      }
    };

    try {
      const updatedWorkingtime = await this.request.put(`/api/workingtime/${userId}`, workingtimeData);
      return updatedWorkingtime;
    } catch (error) {
      console.error(`Error updating working time for user ${userId}:`, error);
      throw error;
    }
  }

  async deleteWorkingtime(workingtimeId) {
    try {
      await this.request.delete(`/api/workingtime/${workingtimeId}`);
    } catch (error) {
      console.error(`Error deleting working time with ID ${workingtimeId}:`, error);
      throw error;
    }
  }
}

export default WorkingTime;