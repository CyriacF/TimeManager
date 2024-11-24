import axios from 'axios';

class Weather {
    constructor() {
    }
  async getWeather(city) {
    try {
      const apiKey = "7b02fe408d03b32ccc2a5e44d3f2f1bd";
      const response = await axios.get(`https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}&units=metric`);
      const weatherData = response.data;

      // Extracting the required information
      const weatherCondition = weatherData.weather[0].main;
      const temperature = Math.trunc(weatherData.main.temp);
      const iconWeather = `https://openweathermap.org/img/wn/${weatherData.weather[0].icon}.png`;

      // Returning the simplified object
      return {
        weatherCondition,
        temperature,
          iconWeather
      };
    } catch (error) {
      console.error('Error fetching weather:', error);
      throw error;
    }
  }

}

export default Weather;