package org.weather;

import java.nio.file.Paths;
import java.util.logging.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.weather.controllers.WeatherController;

import io.github.cdimascio.dotenv.Dotenv;

@SpringBootApplication
@RestController
public class App {
    public static void main(String[] args) {
        Logger logger = Logger.getLogger(WeatherController.class.getName());
        logger.info("Starting Weather Application...");
        logger.info("Loading environment variables from .env file...");
        String envPath = Paths.get(System.getProperty("user.dir"), "..", ".env").normalize().toString();

        if (!Paths.get(envPath).toFile().exists()) {
            logger.warning("The .env file does not exist at the specified path: " + envPath);
        } else {
            logger.info("Using .env file at: " + envPath);
        }

        Dotenv dotenv = Dotenv.configure()
                .directory(envPath)
                .ignoreIfMissing()
                .filename(".env")
                .load();

        var env = dotenv.entries();

        for (var entry : env) {
            System.setProperty(entry.getKey(), entry.getValue());
        }

        logger.info("Environment variables loaded successfully.");
        logger.info("Starting Spring Boot application...");
        SpringApplication.run(App.class, args);
    }
}