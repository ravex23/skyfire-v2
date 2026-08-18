resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-oidc"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "AllowGitHubActions"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.github_actions_ci_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-ci"
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  ecr_repository_arn = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
  eks_cluster_arn    = "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"

  terraform_state_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"

  terraform_state_keys = [
    "skyfire/state-backend/terraform.tfstate",
    "skyfire/github-identity/terraform.tfstate",
    "skyfire/eks/terraform.tfstate"
  ]
}

data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    sid    = "AllowECRAuthentication"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowSkyFireImagePush"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = [
      local.ecr_repository_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "${var.github_actions_ci_role_name}-ecr"
  description = "Allows the SkyFire GitHub Actions role to push images to its ECR repository"
  policy      = data.aws_iam_policy_document.github_actions_ecr.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-ecr"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

resource "aws_iam_role" "github_actions_cd" {
  name               = var.github_actions_cd_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-cd"
  }
}

data "aws_iam_policy_document" "github_actions_cd_eks" {
  statement {
    sid    = "AllowSkyFireClusterDiscovery"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster"
    ]

    resources = [
      local.eks_cluster_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_cd_eks" {
  name        = "${var.github_actions_cd_role_name}-eks"
  description = "Allows the SkyFire GitHub Actions CD role to discover its EKS cluster"
  policy      = data.aws_iam_policy_document.github_actions_cd_eks.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-cd-eks"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_cd_eks" {
  role       = aws_iam_role.github_actions_cd.name
  policy_arn = aws_iam_policy.github_actions_cd_eks.arn
}

resource "aws_iam_role" "github_actions_bootstrap" {
  name               = var.github_actions_bootstrap_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-bootstrap"
  }
}

data "aws_iam_policy_document" "github_actions_bootstrap_eks" {
  statement {
    sid    = "AllowSkyFireClusterDiscovery"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster"
    ]

    resources = [
      local.eks_cluster_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_bootstrap_eks" {
  name        = "${var.github_actions_bootstrap_role_name}-eks"
  description = "Allows the SkyFire GitHub Actions bootstrap role to discover its EKS cluster"
  policy      = data.aws_iam_policy_document.github_actions_bootstrap_eks.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-bootstrap-eks"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_bootstrap_eks" {
  role       = aws_iam_role.github_actions_bootstrap.name
  policy_arn = aws_iam_policy.github_actions_bootstrap_eks.arn
}

resource "aws_iam_role" "github_actions_terraform_plan" {
  name               = var.github_actions_terraform_plan_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-plan"
  }
}

data "aws_iam_policy_document" "github_actions_terraform_plan" {
  statement {
    sid    = "ReadTerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucket*",
      "s3:ListBucket"
    ]

    resources = [
      local.terraform_state_bucket_arn
    ]
  }

  statement {
    sid    = "ReadTerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      for key in local.terraform_state_keys :
      "${local.terraform_state_bucket_arn}/${key}"
    ]
  }

  statement {
    sid    = "ReadAWSInfrastructure"
    effect = "Allow"

    actions = [
      "autoscaling:Describe*",
      "ec2:Describe*",
      "ecr:Describe*",
      "ecr:List*",
      "eks:Describe*",
      "eks:List*",
      "elasticloadbalancing:Describe*",
      "iam:Get*",
      "iam:List*",
      "kms:Describe*",
      "kms:List*",
      "logs:Describe*",
      "logs:List*",
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_terraform_plan" {
  name        = "${var.github_actions_terraform_plan_role_name}-read"
  description = "Allows Terraform plan to read SkyFire state and inspect AWS infrastructure"
  policy      = data.aws_iam_policy_document.github_actions_terraform_plan.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-plan"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_plan" {
  role       = aws_iam_role.github_actions_terraform_plan.name
  policy_arn = aws_iam_policy.github_actions_terraform_plan.arn
}
