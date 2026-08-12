terraform {
  required_version = "~> 1.15.0"

  backend "s3" {
    bucket       = "skyfire-terraform-state-182399705651"
    key          = "skyfire/state-backend/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
