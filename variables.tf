variable "bootstrap_step" {
  description = "Flag to bootstrap infra in order"
  type        = number
  default     = 1
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "efs_id" {
  description = "The ID of the EFS file system to use for persistent storage"
  type        = string
}

variable "server_name" {
  description = "The public-facing domain for the Matrix server"
  type        = string
}

variable "matrix_domain" {
  description = "The domain name for the Matrix instance"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS cluster is created"
  type        = string
}

variable "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  type        = string
}

variable "alb_security_group_id" {
  description = "The security group ID for the Application Load Balancer"
  type        = string
}

variable "environment_name" {
  description = "The name of the environment (e.g., development, staging, production)"
  type        = string
}

variable "matrix_instance_id" {
  description = "The human-readable ID of the Matrix instance"
  type        = string
}

variable "route53_zone_id" {
  description = "The ID of the Route53 hosted zone"
  type        = string
  default     = ""
}

variable "enable_execute_command" {
  description = "Flag to enable ECS execute command feature"
  type        = bool
  default     = false
}

# == Synapse container variables ==

variable "synapse_container_image" {
  description = "The Docker image for the Synapse container"
  type        = string
}

variable "synapse_container_image_tag" {
  description = "The tag for the Docker image for the Synapse container"
  type        = string
}

variable "synapse_desired_count" {
  description = "The desired count for the Synapse task"
  type        = number
  default     = 1
}

variable "synapse_task_cpu" {
  description = "The CPU units for the Synapse task"
  type        = number
  default     = 2048
}

variable "synapse_task_memory" {
  description = "The memory (in MiB) for the Synapse task"
  type        = number
  default     = 4096
}

variable "synapse_variables" {
  description = "Additional environment variables for the Synapse application"
  type        = map(string)
  default     = {}
}


# == Element Web container variables ==

variable "web_container_image" {
  description = "The Docker image for the Element Web container"
  type        = string
}

variable "web_container_image_tag" {
  description = "The tag for the Docker image for the Element Web container"
  type        = string
}

variable "web_desired_count" {
  description = "The desired count for the Element Web task"
  type        = number
  default     = 1
}

variable "web_task_cpu" {
  description = "The CPU units for the Element Web task"
  type        = number
  default     = 512
}

variable "web_task_memory" {
  description = "The memory (in MiB) for the Element Web task"
  type        = number
  default     = 1024
}

variable "web_variables" {
  description = "Additional environment variables for the Element Web application"
  type        = map(string)
  default     = {}
}
