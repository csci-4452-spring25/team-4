# Use an official OpenJDK runtime as a parent image
FROM openjdk:22-jdk-slim AS build

# Set the working directory for the build stage
WORKDIR /app

# Copy Gradle wrapper and configuration files
COPY gradlew gradlew.bat settings.gradle.kts gradle.properties /app/
COPY gradle /app/gradle

# Copy the application source code
COPY app /app/app

# Grant execution permission to the Gradle wrapper
RUN chmod +x gradlew

# Build the application JAR file
RUN ./gradlew :app:bootJar

# Use a smaller image for the runtime
FROM openjdk:22-jdk-slim

# Set the working directory for the runtime stage
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/app/build/libs/app-boot.jar app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]