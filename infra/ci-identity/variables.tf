variable "aws_region" {
  description = "AWS region used by the SkyFire CI pipeline"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository"
  type        = string
  default     = "ravex23"
}

variable "github_repository" {
  description = "GitHub repository trusted to assume the CI role"
  type        = string
  default     = "skyfire-v2"
}

variable "github_branch" {
  description = "GitHub branch trusted to assume the CI role"
  type        = string
  default     = "main"
}

variable "ecr_repository_name" {
  description = "ECR repository the CI role may publish images to"
  type        = string
  default     = "skyfire-api"
}

variable "github_actions_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
  default     = "skyfire-github-actions"
}