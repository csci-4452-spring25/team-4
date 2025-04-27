variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "db_username" {
  type    = string
  default = "postgres"
  validation {
    condition     = length(var.db_username) > 0
    error_message = "DB username cannot be empty"
  }
}

variable "db_password" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "db_name" {
  type    = string
  default = "default_db"
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
