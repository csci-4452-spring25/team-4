data "external" "env" {
  program = ["${path.module}/env.sh"]
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "db_username" {
  type    = string
  default = data.external.env.result["DB_USERNAME"]
}

variable "db_password" {
  type      = string
  sensitive = true
  nullable  = false
  default   = data.external.env.result["DB_PASSWORD"]
}

variable "db_name" {
  type    = string
  default = data.external.env.result["DB_NAME"]
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
  default = data.external.env.result["AWS_ACCESS_KEY"]
}

variable "secret_key" {
  type      = string
  sensitive = true
  default = data.external.env.result["AWS_SECRET_KEY"]
}