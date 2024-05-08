variable "domain_name" {
  type        = string
  description = "A domain name for which the certificate should be issued"
  default     = "maciej.aws.enterpriseme.academy"
}

variable "zone_id" {
  type        = string
  description = "The ID of the hosted zone to contain this record. Required when validating via Route53"
  default     = "Z0471614CY2S84LBMTIH"
}

#######################

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  domain_name         = var.domain_name
  zone_id             = var.zone_id
  validation_method   = "DNS"
  wait_for_validation = true
  tags                = var.common_tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.4.0"

  load_balancer_type = "application"
  name               = "${var.name}-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.public.id, aws_security_group.private.id]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [{
    port               = 443
    protocol           = "HTTPS"
    certificate_arn    = module.acm.acm_certificate_arn
    target_group_index = 0
    }
  ]
  target_groups = [
    {
      backend_port                      = 8080
      backend_protocol                  = "HTTP"
      target_type                       = "instance"
      load_balancing_cross_zone_enabled = true
      # There's nothing to attach here in this definition.
      # The attachment happens in the ASG module above
      create_attachment = false
      health_check = {
        path                = "/login"
        enabled             = true
        interval            = 30
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name}-alb"
  })
}

resource "aws_route53_record" "dns_name" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.lb_dns_name]
}
