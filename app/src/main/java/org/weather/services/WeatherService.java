package org.weather.services;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.client.RestTemplate;

@Service
public class WeatherService {

    @Value("${WEATHER_API_URL:https://api.openweathermap.org/data/2.5/weather}")
    private String apiUrl;

    @Value("${OPENWEATHER_APP_ID}")
    private String apiKey;

    public String getWeatherUrl(String city) {
        return apiUrl + "?q=" + city + "&appid=" + apiKey;
    }

    public String getWeather(String city) {
        RestTemplate restTemplate = new RestTemplate();
        String url = getWeatherUrl(city);
        String response = restTemplate.getForObject(url, String.class);
        return response;
    }  
}
