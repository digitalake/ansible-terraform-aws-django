# VPC  module vars

variable "vpc_name" {
  type = string
  description = "name for primary VPC"
  default = "main"
}

variable "vpc_cidr" {
  type = string
  description = "CODR block for primary VPC"
  default = "10.0.0.16"
}

variable "vpc_azs" {
  type = list(string)
  description = "Avaliability zones for the primary VPC"
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_private_subnets" {
  type = list(string)
  description = "Private subnet CIDRs"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  type = list(string)
  description = "Public subnet CIDRs. Make sure to specify at leats 2 public subnets in two azs for ALB"
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_enable_nat_gateway" {
  type = bool
  description = "Enable or disable NAT for private subnets"
  default = true
}

variable "vpc_single_nat_gateway" {
  type = bool
  description = "Enable or disable single NAT"
  default = false
}


# Application module vars

# In this particular configuration, all instances use singe configuration

variable "app_instance_keys" {
  type = list(string)
  description = "A list to iterate through for creating instances"
  default = null
}

variable "app_instance_type" {
  type = string
  description = "Specify instance type"
  default = "t2.micro"
}

variable "app_ami" {
  type = string
  description = "Specify instance AMI"
  default = "ami-053b0d53c279acc90"
  validation {
    condition     = length(var.app_ami) > 4 && substr(var.app_ami, 0, 4) == "ami-"
    error_message = "The app_ami value must be a valid AMI id, starting with \"ami-\"."
  }
}

# Bastion module vars

variable "bastion_name" {
  type = string
  description = "Bastion host name"
  default = "bastion"
}

variable "bastion_instance_type" {
  type = string
  description = "Specify instance type"
  default = "t2.micro"
}

variable "bastion_ami" {
  type = string
  description = "Specify instance AMI"
  default = "ami-053b0d53c279acc90"
  validation {
    condition     = length(var.bastion_ami) > 4 && substr(var.bastion_ami, 0, 4) == "ami-"
    error_message = "The bastion_ami value must be a valid AMI id, starting with \"ami-\"."
  }
}

# DB module vars

variable "db_name" {
  type = string
  description = "Database host name"
  default = "database"
}

variable "db_instance_type" {
  type = string
  description = "Specify instance type"
  default = "t2.micro"
}

variable "db_ami" {
  type = string
  description = "Specify instance AMI"
  default = "ami-053b0d53c279acc90"
  validation {
    condition     = length(var.db_ami) > 4 && substr(var.db_ami, 0, 4) == "ami-"
    error_message = "The db_ami value must be a valid AMI id, starting with \"ami-\"."
  }
}


# ALB module variables

variable "alb_name" {
  type = string
  description = "Application load balancer name"
  default = "application-lb"
}


# common vars

variable "ssh_public_key_path" {
  type = string
  description = "Specify the ssh key path to use for provisioning"
  default = "~/.ssh/key.pub"
}




