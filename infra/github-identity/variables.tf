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

variable "github_actions_ci_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
  default     = "skyfire-github-actions"
}

variable "github_actions_cd_role_name" {
  description = "Name of the IAM role assumed by the SkyFire CD job"
  type        = string
  default     = "skyfire-github-actions-cd"
}

variable "eks_cluster_name" {
  description = "EKS cluster the CD role may discover"
  type        = string
  default     = "skyfire-eks"
}

variable "github_actions_bootstrap_role_name" {
  description = "Name of the IAM role assumed by the SkyFire bootstrap workflow"
  type        = string
  default     = "skyfire-github-actions-bootstrap"
}

variable "github_actions_terraform_plan_role_name" {
  description = "Name of the read-only IAM role used by Terraform plan"
  type        = string
  default     = "skyfire-github-actions-terraform-plan"
}

variable "terraform_state_bucket_name" {
  description = "S3 bucket containing the SkyFire Terraform state files"
  type        = string
  default     = "skyfire-terraform-state-182399705651"
}

variable "github_actions_terraform_apply_role_name" {
  description = "Name of the approval-gated IAM role used by Terraform apply"
  type        = string
  default     = "skyfire-github-actions-terraform-apply"
}

variable "github_actions_terraform_apply_environment" {
  description = "GitHub environment authorized to assume the Terraform apply role"
  type        = string
  default     = "terraform-apply"
}
