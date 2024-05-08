#EFS
module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.3.1"

  name          = var.name
  attach_policy = false
  mount_targets = {
    "eu-west-1a" = {
      subnet_id = module.vpc.private_subnets[0]
    }
    "eu-west-2" = {
      subnet_id = module.vpc.private_subnets[1]
    }
  }
  security_group_description = "EFS security group"
  security_group_name        = "${var.name}-efs"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }
  # Backup policy
  enable_backup_policy = false
  tags                 = var.common_tags
}
