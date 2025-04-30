---
title: Project Documentation
description: Documentation for the Spring Boot project using Terraform, AWS, and GitHub Actions.
aside: true
---

# Cloud-Native Spring Boot on AWS

Welcome to the documentation for this cloud-native web application. It's built with **Spring Boot**, provisioned with **Terraform**, deployed on **AWS ECS**, and automated via **GitHub Actions**. This project demonstrates a modern DevOps workflow, scalable infrastructure, and robust CI/CD practices.

## 🚀 Quick Overview
- **Language:** Java (Spring Boot)
- **Cloud:** AWS (ECS, S3, IAM, CloudWatch, ECR)
- **Infrastructure as Code:** Terraform
- **CI/CD:** GitHub Actions
- **Docs:** VitePress

## 📦 Main Features
- **Automated Infrastructure:** Provision AWS resources (ECS, S3, IAM, etc.) using Terraform.
- **Containerized Deployments:** Build and deploy Docker images to AWS ECS Fargate.
- **CI/CD Pipelines:** Automated build, test, and deployment workflows with GitHub Actions.
- **Weather Data:** Integrates with OpenWeather API for real-time weather and forecast data.
- **CSV Export:** Users can generate and download weather data as CSV files, stored in S3.

## 🗺️ Architecture Diagram
![Architecture Diagram](./icons/architecture.svg)

## 📝 Example: Weather Data to CSV and S3
```java
@PostMapping("/generate-csv")
public String generateCsv(@RequestParam("cities") String citiesInput, Model model) {
    // ...existing code...
    storageService.uploadCsv(tempFile.toFile(), s3Key);
    // ...existing code...
}
```
- User submits cities → Weather data fetched → CSV generated → Uploaded to S3.
