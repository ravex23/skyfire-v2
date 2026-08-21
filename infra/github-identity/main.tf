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

data "aws_iam_policy_document" "github_actions_terraform_apply_assume_role" {
  statement {
    sid     = "AllowApprovedGitHubEnvironment"
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
        "repo:${var.github_owner}/${var.github_repository}:environment:${var.github_actions_terraform_apply_environment}"
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

  terraform_eks_state_key    = "skyfire/eks/terraform.tfstate"
  terraform_eks_lockfile_key = "skyfire/eks/terraform.tfstate.tflock"

  eks_node_group_arn   = "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:nodegroup/${var.eks_cluster_name}/*/*"
  eks_access_entry_arn = "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:access-entry/${var.eks_cluster_name}/*"
  eks_log_group_arn    = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.eks_cluster_name}/cluster:*"

  eks_cluster_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/skyfire-eks-cluster-*"
  eks_node_role_arn    = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/skyfire-ng-eks-node-group-*"
  lbc_role_arn         = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/skyfire-aws-load-balancer-controller"

  eks_cluster_policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/skyfire-eks-cluster-*"
  lbc_policy_arn         = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/skyfire-aws-load-balancer-controller"

  eks_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.aws_region}.amazonaws.com/id/*"

  eks_kms_key_arn   = "arn:${data.aws_partition.current.partition}:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
  eks_kms_alias_arn = "arn:${data.aws_partition.current.partition}:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/eks/${var.eks_cluster_name}"
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
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
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
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
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

resource "aws_iam_role" "github_actions_terraform_apply" {
  name               = var.github_actions_terraform_apply_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_terraform_apply_assume_role.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-apply"
  }
}

data "aws_iam_policy_document" "github_actions_terraform_apply" {
  statement {
    sid    = "InspectTerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucket*",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]

    resources = [
      local.terraform_state_bucket_arn
    ]
  }

  statement {
    sid    = "ManageEKSState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${local.terraform_state_bucket_arn}/${local.terraform_eks_state_key}"
    ]
  }

  statement {
    sid    = "ManageEKSStateLock"
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${local.terraform_state_bucket_arn}/${local.terraform_eks_lockfile_key}"
    ]
  }

  statement {
    sid    = "ReadEKSInfrastructure"
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

  statement {
    sid    = "ManageEKSNetworking"
    effect = "Allow"

    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateNatGateway",
      "ec2:CreateNetworkAclEntry",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersion",
      "ec2:DeleteNatGateway",
      "ec2:DeleteNetworkAclEntry",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyLaunchTemplate",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceNetworkAclEntry",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "LaunchEKSManagedNodes"
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "ec2:LaunchTemplate"
      values = [
        "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
      ]
    }
  }

  statement {
    sid    = "ManageEKSCluster"
    effect = "Allow"

    actions = [
      "eks:AssociateAccessPolicy",
      "eks:CreateAccessEntry",
      "eks:CreateCluster",
      "eks:CreateNodegroup",
      "eks:DeleteAccessEntry",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "eks:DisassociateAccessPolicy",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:UpdateAccessEntry",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion"
    ]

    resources = [
      local.eks_cluster_arn,
      local.eks_node_group_arn,
      local.eks_access_entry_arn
    ]
  }

  statement {
    sid    = "ManageEKSClusterLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DeleteRetentionPolicy",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource"
    ]

    resources = [
      local.eks_log_group_arn
    ]
  }
}

data "aws_iam_policy_document" "github_actions_terraform_apply_iam" {
  statement {
    sid    = "ManageEKSManagedRoles"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DetachRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription"
    ]

    resources = [
      local.eks_cluster_role_arn,
      local.eks_node_role_arn,
      local.lbc_role_arn
    ]
  }

  statement {
    sid    = "ManageEKSManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]

    resources = [
      local.eks_cluster_policy_arn,
      local.lbc_policy_arn
    ]
  }

  statement {
    sid    = "PassEKSManagedRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      local.eks_cluster_role_arn,
      local.eks_node_role_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ec2.amazonaws.com",
        "eks.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "ManageEKSOIDCProvider"
    effect = "Allow"

    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint"
    ]

    resources = [
      local.eks_oidc_provider_arn
    ]
  }

  statement {
    sid    = "CreateRequiredServiceLinkedRoles"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "elasticloadbalancing.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "github_actions_terraform_apply_iam" {
  name        = "${var.github_actions_terraform_apply_role_name}-iam"
  description = "Allows Terraform apply to manage only IAM resources required by SkyFire EKS"
  policy      = data.aws_iam_policy_document.github_actions_terraform_apply_iam.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-apply"
  }
}

data "aws_iam_policy_document" "github_actions_terraform_apply_kms" {
  statement {
    sid    = "CreateTaggedEKSKey"
    effect = "Allow"

    actions = [
      "kms:CreateKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = ["skyfire"]
    }
  }

  statement {
    sid    = "ManageTaggedEKSKeys"
    effect = "Allow"

    actions = [
      "kms:CancelKeyDeletion",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:EnableKey",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateKeyDescription"
    ]

    resources = [
      local.eks_kms_key_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = ["skyfire"]
    }
  }

  statement {
    sid    = "ManageEKSKeyAlias"
    effect = "Allow"

    actions = [
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:UpdateAlias"
    ]

    resources = [
      local.eks_kms_alias_arn,
      local.eks_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_terraform_apply_kms" {
  name        = "${var.github_actions_terraform_apply_role_name}-kms"
  description = "Allows Terraform apply to manage the tagged SkyFire EKS encryption key"
  policy      = data.aws_iam_policy_document.github_actions_terraform_apply_kms.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-apply"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_apply_kms" {
  role       = aws_iam_role.github_actions_terraform_apply.name
  policy_arn = aws_iam_policy.github_actions_terraform_apply_kms.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_apply_iam" {
  role       = aws_iam_role.github_actions_terraform_apply.name
  policy_arn = aws_iam_policy.github_actions_terraform_apply_iam.arn
}

resource "aws_iam_policy" "github_actions_terraform_apply" {
  name        = "${var.github_actions_terraform_apply_role_name}-eks"
  description = "Allows approved GitHub Actions runs to manage SkyFire EKS infrastructure"
  policy      = data.aws_iam_policy_document.github_actions_terraform_apply.json

  tags = {
    Project = "skyfire"
    Purpose = "github-actions-terraform-apply"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_apply" {
  role       = aws_iam_role.github_actions_terraform_apply.name
  policy_arn = aws_iam_policy.github_actions_terraform_apply.arn
}
