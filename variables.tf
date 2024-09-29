variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "terraform-cicd"
}

variable "env" {
  description = "The environment (e.g. dev, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region."
  type        = string
  default     = "ap-northeast-1"
}

variable "repository" {
  description = "github repository"
  type        = string
  default     = "yusa0730/ecr-cicd"
}

variable "branch" {
  description = "github branch"
  type        = string
  default     = "main"
}
