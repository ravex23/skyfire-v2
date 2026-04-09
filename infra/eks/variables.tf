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