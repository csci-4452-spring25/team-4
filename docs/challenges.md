---
title: Challenges Encountered
---

## Challenges Encountered

### Technical Obstacles

-   **Terraform State Management:** Ensuring state consistency and handling remote state backends for team collaboration.
-   **Docker Networking:** Debugging container networking issues in ECS Fargate - Still unresolved.
-   **CI/CD Secrets Management:** Securely managing AWS credentials and API keys both in GitHub Actions and container environment - consistency issues.

### Solutions and Workarounds

-   Used Terraform best practices for state and resource dependencies, imported any unmanage resources.
-   As for the secrets, we just made sure to be careful with naming, using known conventions,
