---
title: Examples
---
## 📝 Example: Terraform ECS Service
```hcl
resource "aws_ecs_service" "app" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.ecr_service_security_group.id]
    assign_public_ip = true
  }
  depends_on = [aws_ecs_task_definition.app]
}
```

## 📝 Example: GitHub Actions CI/CD
```yaml
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Build with Gradle
        run: ./gradlew :app:bootJar
      - name: Build, tag, and push image to ECR
        run: |
          docker build -t $AWS_ECR_REGISTRY/$AWS_ECR_REPOSITORY:latest -f Dockerfile .
          docker push $AWS_ECR_REGISTRY/$AWS_ECR_REPOSITORY:latest
      - name: Update ECS service to use new task definition
        run: |
          aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE --task-definition ${{ steps.register-task-def.outputs.task_def_arn }}
```

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

