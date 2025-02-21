variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project (e.g., Darwin)"
  type        = string
  default     = "Darwin"
}

variable "service_name" {
  description = "Name of the service (e.g., PsyCore)"
  type        = string
  default     = "PsyCore"
}

variable "team_members" {
  description = "List of team member names"
  type        = list(string)
  default = [
    "Sebastian",
    "Anastasiia",
    "Jasmine",
    "Arun",
    "Louis"
  ]
}