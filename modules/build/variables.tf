variable "project_name" {
  description = "The project name, used to name resources"
}

variable "ssm_template_file" {
  description = "use this to pass a custom ssm_template_into the project"
  default     = ""
}

variable "vpc_id" {
  description = "VPC id to be used by by the ami build pipeline. Use Tfvars to override"
}

variable "private_subnets_ids" {
  type        = list(any)
  description = "The IDs for the subnets"
}

variable "tags" {
  type        = map(any)
  description = "A map of tags to add to all resources."
  default     = {}
}

variable "build_ami_userdata" {
  description = "User data for the build ami"
  default     = ""
}

variable "build_cycle_cron" {
  type        = string
  default     = "cron(0 8 * * ? *)"
  description = "(Optional) Cron expression for the time between the cycle triggers of the SSM build pipeline. https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

variable "image_name_prefix" {
  type        = string
  description = "Name prefix for the image to be build"
}

variable "efs_id" {
  type        = string
  description = "ID of EFS file system"
}
