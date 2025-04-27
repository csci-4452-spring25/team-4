package org.weather.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.weather.services.WeatherService;
import org.weather.services.StorageService;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.util.logging.Logger;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONObject;
import org.json.JSONArray;

@Controller
public class WeatherController {

    private final WeatherService weatherService;
    private final StorageService storageService;
    private final Logger logger = Logger.getLogger(WeatherController.class.getName());

    @Autowired
    public WeatherController(WeatherService weatherService, StorageService storageService) {
        this.weatherService = weatherService;
        this.storageService = storageService;
    }

    @GetMapping("/weather")
    public String getWeather(@RequestParam String city) {
        return weatherService.getWeather(city);
    }

    @PostMapping("/generate-csv")
    public String generateCsv(@RequestParam("cities") String citiesInput, Model model) {
        try {
            // Input validation
            if (citiesInput == null || citiesInput.trim().isEmpty()) {
                model.addAttribute("error", "Please enter at least one city.");
                return "home";
            }
            String[] cities = citiesInput.split("[\n,]+");
            List<String[]> csvRows = new ArrayList<>();
            csvRows.add(new String[] { "City", "Date", "Temperature", "Weather", "Description" });
            boolean atLeastOneSuccess = false;
            StringBuilder errorCities = new StringBuilder();
            for (String cityRaw : cities) {
                String city = cityRaw.trim();
                if (city.isEmpty())
                    continue;
                try {
                    // Get coordinates for the city
                    String geoJson = weatherService.getCoordinates(city);
                    JSONArray geoArr = new JSONArray(geoJson);
                    if (geoArr.isEmpty()) {
                        errorCities.append(city).append(", ");
                        continue;
                    }
                    JSONObject geo = geoArr.getJSONObject(0);
                    double lat = geo.getDouble("lat");
                    double lon = geo.getDouble("lon");
                    String country = geo.optString("country", "");
                    String state = geo.optString("state", "");
                    String displayName = city;
                    if (!state.isEmpty())
                        displayName += ", " + state;
                    if (!country.isEmpty())
                        displayName += ", " + country;
                    // Get forecast by coordinates
                    String forecastJson = weatherService.getForecastByCoords(lat, lon);
                    JSONObject forecastObj = new JSONObject(forecastJson);
                    if (!forecastObj.has("list")) {
                        errorCities.append(city).append(", ");
                        continue;
                    }
                    JSONArray list = forecastObj.getJSONArray("list");
                    for (int i = 0; i < list.length(); i++) {
                        JSONObject item = list.getJSONObject(i);
                        String date = item.getString("dt_txt");
                        double temp = item.getJSONObject("main").getDouble("temp");
                        JSONObject weather = item.getJSONArray("weather").getJSONObject(0);
                        String main = weather.getString("main");
                        String desc = weather.getString("description");
                        csvRows.add(new String[] { displayName, date, String.valueOf(temp), main, desc });
                    }
                    atLeastOneSuccess = true;
                } catch (Exception ex) {
                    if (errorCities.length() > 0) {
                        errorCities.append(", ");
                    }
                    errorCities.append(city);
                    model.addAttribute("error", "Failed to process city: " + city + ". Error: " + ex.getMessage());
                    logger.warning("Failed to process city: " + city + ". Error: " + ex.getMessage());
                    continue;
                }
            }
            if (!atLeastOneSuccess) {
                model.addAttribute("error",
                        "No valid weather data found for the entered cities. Please check your input.");
                if (errorCities.length() > 0) {
                    model.addAttribute("warning", "Some cities could not be processed: " + errorCities.toString());
                }
                return "home";
            }
            // Write CSV to temp file
            Path tempFile = Files.createTempFile("weather-", ".csv");
            try (PrintWriter pw = new PrintWriter(new FileWriter(tempFile.toFile()))) {
                for (String[] row : csvRows) {
                    pw.println(String.join(",", row));
                }
                pw.flush();
                pw.close();
            }
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
            String s3Key = "weather-" + timestamp + ".csv";
            storageService.uploadCsv(tempFile.toFile(), s3Key);
            Files.deleteIfExists(tempFile);
            model.addAttribute("cities", citiesInput);
            model.addAttribute("csvKey", s3Key);
            model.addAttribute("success", "CSV generated and uploaded successfully!");
            if (errorCities.length() > 0) {
                model.addAttribute("warning", "Some cities could not be processed: " + errorCities.toString());
            }
            return "home";
        } catch (Exception e) {
            model.addAttribute("error", "Failed to generate CSV: " + e.getMessage());
            logger.warning("Failed to generate CSV: " + e.getMessage());
            return "home";
        }
    }

    @GetMapping("/csv")
    public String downloadCsv(@RequestParam("key") String key, Model model) {
        var hasCsv = storageService.hasCsv(key);
        if (!hasCsv) {
            model.addAttribute("error", "CSV file not found: " + key);
            return "home";
        }
        model.addAttribute("csvKey", key);
        model.addAttribute("success", "CSV file is available for download.");
        return "redirect:/csv/download?key=" + key;
    }

    @GetMapping("/csv/download")
    public ResponseEntity<InputStreamResource> downloadCsvFile(@RequestParam("key") String key) {
        InputStreamResource resource;
        try {
            resource = storageService.downloadCsv(key);
        } catch (IOException e) {
            logger.warning("Failed to download CSV file: " + e.getMessage());
            return ResponseEntity.status(500).body(null);
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + key)
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(resource);
    }
}
