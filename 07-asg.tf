## AutoScaling Group
module "asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "7.4.1"
  name                      = var.name
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  create_scaling_policy     = false
  create_schedule           = false
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.vpc.private_subnets
  create_launch_template    = false
  launch_template_id        = aws_launch_template.template.id
  launch_template_version   = "$Latest"
  target_group_arns         = [module.alb.target_group_arns[0]]
  max_instance_lifetime     = 604800
  tags = merge(
    var.common_tags,
    {
      Name = var.name
  })
}
