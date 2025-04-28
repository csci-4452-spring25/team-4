variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "monthly_budget_amount" {
  type    = number
  default = 100
}

variable "budget_alert_email" {
  description = "email address for budget alerts"
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be either dev, staging, or prod"
  }
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "open_weather_app_id" {
  type        = string
  description = "OpenWeather API key"
  default     = ""
  sensitive   = true
  validation {
    condition     = length(var.open_weather_app_id) > 0
    error_message = "OpenWeather API key cannot be empty"
  }
}
