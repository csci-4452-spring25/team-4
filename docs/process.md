---
title: Summary of the Process
---

## Summary of the Process

### Infrastructure Provisioning with Terraform

-   **Terraform** scripts define all AWS resources: ECS cluster, task definitions, S3 bucket, IAM roles, security groups, and networking.
-   Running `terraform apply` provisions or updates the infrastructure in a repeatable, version-controlled manner.
-   The ECS service is configured to run the Dockerized Spring Boot app, with environment variables and logging set up for observability.

### CI/CD with GitHub Actions

-   **GitHub Actions** workflows automate the build, test, and deployment process:
    -   On push to `main`, the workflow builds the Spring Boot JAR, creates a Docker image, and pushes it to AWS ECR.
    -   The ECS task definition is updated with the new image, and the ECS service is updated to deploy the latest version.
    -   Separate workflow builds and deploys the VitePress documentation to GitHub Pages.

### Application Deployment

-   The Spring Boot app is containerized and deployed to AWS ECS Fargate, using the infrastructure provisioned by Terraform.
-   Application configuration (such as API keys and S3 bucket names) is managed via environment variables and secrets.

### System Interactions

-   Terraform provisions all AWS resources and outputs configuration for the app.
-   GitHub Actions coordinates code build, Docker image creation, and ECS deployment.
-   The Spring Boot app interacts with AWS S3 for storage and external APIs for weather data.
