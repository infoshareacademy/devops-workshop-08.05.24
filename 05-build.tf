# Build Image
variable "image_name_prefix" {
  type        = string
  description = "Prefix of application image"
  default     = "isa"
}

module "build" {
  source              = "./modules/build"
  private_subnets_ids = module.vpc.private_subnets
  vpc_id              = module.vpc.vpc_id
  project_name        = var.name
  image_name_prefix   = var.image_name_prefix
  efs_id              = module.efs.id
  tags                = var.common_tags
}
