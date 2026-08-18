variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "skyfire"
}

variable "cluster_name" {
  type    = string
  default = "skyfire-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "github_actions_cd_role_arn" {
  description = "ARN of the GitHub Actions CD role authorized to deploy SkyFire"
  type        = string
}

variable "github_actions_bootstrap_role_arn" {
  description = "ARN of the GitHub Actions role authorized to bootstrap EKS add-ons"
  type        = string
}

variable "terraform_apply_role_arn" {
  description = "ARN of the GitHub Actions role authorized to administer the EKS KMS key"
  type        = string
}
