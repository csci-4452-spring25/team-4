---
title: Challenges Encountered
---

## Challenges Encountered

### Technical Obstacles

-   **Terraform State Management:** Ensuring state consistency and handling remote state backends for team collaboration.
-   **AWS IAM Permissions:** Configuring least-privilege IAM roles for ECS tasks and deployment automation.
-   **Docker Networking:** Debugging container networking issues in ECS Fargate.
-   **CI/CD Secrets Management:** Securely managing AWS credentials and API keys in GitHub Actions.
-   **Resource Dependencies:** Coordinating resource creation order in Terraform to avoid race conditions.

### Solutions and Workarounds

-   Used Terraform best practices for state and resource dependencies.
-   Leveraged GitHub Secrets and AWS IAM roles for secure automation.
-   Iteratively tested and refined ECS task definitions and networking settings.
