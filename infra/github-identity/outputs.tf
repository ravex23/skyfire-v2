output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository accessible to the CI role"
  value       = local.ecr_repository_arn
}

output "github_actions_cd_role_arn" {
  description = "ARN of the IAM role assumed by the SkyFire CD job"
  value       = aws_iam_role.github_actions_cd.arn
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster discoverable by the CD role"
  value       = local.eks_cluster_arn
}

output "github_actions_bootstrap_role_arn" {
  description = "ARN of the IAM role assumed by the SkyFire bootstrap workflow"
  value       = aws_iam_role.github_actions_bootstrap.arn
}