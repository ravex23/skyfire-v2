variable "aws_region" {
  description = "AWS region containing the Terraform state bucket"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used for Terraform state"
  type        = string
  default     = "skyfire-terraform-state-182399705651"
}
