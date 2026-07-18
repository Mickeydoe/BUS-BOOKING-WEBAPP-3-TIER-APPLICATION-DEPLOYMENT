variable "aws_region" {
  description = "AWS region in which the project will be created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used for project resources."
  type        = string
  default     = "simple-pass-booking"
}

variable "repository_url" {
  description = "Git repository containing the Flask booking application"
  type        = string
}
variable "vpc_cidr" {
  description = "IPv4 range for the project VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the Python application."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum EC2 instances maintained by the ASG."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Initial number of EC2 application instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 application instances."
  type        = number
  default     = 3
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the PostgreSQL database."
  type        = string
  default     = "passbooking"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "passadmin"
}

variable "db_allocated_storage" {
  description = "RDS storage size in GiB."
  type        = number
  default     = 20
}
