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
  name               = var.github_actions_role_name
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
  name        = "${var.github_actions_role_name}-ecr"
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
