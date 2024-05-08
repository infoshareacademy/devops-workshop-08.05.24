variable "name" {
  type        = string
  description = "Name for the vpc"
  default     = "isa-demo"
}

variable "common_tags" {
  type        = map(string)
  description = "Default tags that will be added to all resources"
  default = {
    Owner = "Maciej Malek"
  }
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.1.2"
  name                 = var.name
  cidr                 = "10.0.0.0/24"
  azs                  = ["eu-west-1a", "eu-west-1b"]
  private_subnets      = ["10.0.0.0/26", "10.0.0.64/26"]
  public_subnets       = ["10.0.0.128/26", "10.0.0.192/26"]
  enable_nat_gateway   = true
  create_igw           = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.common_tags
}


resource "aws_security_group" "private" {
  name   = "private"
  vpc_id = module.vpc.vpc_id
  tags = merge(var.common_tags,
    {
      Name = "${var.name}-private"
    }
  )
}

resource "aws_security_group" "public" {
  name   = "public"
  vpc_id = module.vpc.vpc_id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.name}-public"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "private_ingress_1" {
  security_group_id            = aws_security_group.private.id
  description                  = "Access from ALB to EC2 instance"
  referenced_security_group_id = aws_security_group.public.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "private_egress_1" {
  security_group_id = aws_security_group.private.id
  description       = "Outbound access"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}



resource "aws_vpc_security_group_ingress_rule" "public_ingress_1" {
  security_group_id = aws_security_group.public.id
  description       = "HTTP access from Internet to ALB"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "public_ingress_2" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS access from Internet to ALB"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
