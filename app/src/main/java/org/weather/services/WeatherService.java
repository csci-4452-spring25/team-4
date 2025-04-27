package org.weather.services;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.client.RestTemplate;

@Service
public class WeatherService {

    @Value("${WEATHER_API_URL:https://api.openweathermap.org/data/2.5}")
    private String apiUrl;

    @Value("${OPENWEATHER_APP_ID}")
    private String apiKey;

    @Value("${COODINATES_API_URL:https://api.openweathermap.org/geo/1.0/direct}")
    private String geoApiUrl;

    @Value("${COODINATES_API_KEY:${OPENWEATHER_APP_ID}}")
    private String geoApiKey;

    public String getWeatherUrl(String city) {
        return apiUrl + "/weather" + "?q=" + city + "&appid=" + apiKey;
    }

    public String getForecastUrl(String city) {
        return apiUrl + "/forecast" + "?q=" + city + "&appid=" + apiKey;
    }

    public String getWeather(String city) {
        RestTemplate restTemplate = new RestTemplate();
        String url = getWeatherUrl(city);
        String response = restTemplate.getForObject(url, String.class);
        return response;
    }

    public String getForecast(String city) {
        RestTemplate restTemplate = new RestTemplate();
        String url = getForecastUrl(city);
        String response = restTemplate.getForObject(url, String.class);
        return response;
    }

    public String getCoordinates(String city) {
        RestTemplate restTemplate = new RestTemplate();
        String url = geoApiUrl + "?q=" + city + "&limit=1&appid=" + geoApiKey;
        return restTemplate.getForObject(url, String.class);
    }

    public String getForecastByCoords(double lat, double lon) {
        RestTemplate restTemplate = new RestTemplate();
        String url = apiUrl + "/forecast?lat=" + lat + "&lon=" + lon + "&appid=" + apiKey;
        return restTemplate.getForObject(url, String.class);
    }
}
