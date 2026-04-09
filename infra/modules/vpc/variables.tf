variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
}