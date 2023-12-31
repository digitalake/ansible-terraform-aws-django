module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"


  name               = var.alb_name
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = "lb"
  }

  security_group_name = "alb-sg"
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_all_icmp = {
      type        = "ingress"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name_prefix                       = "g1"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }

      targets = {
        for instance_name in toset(var.app_instance_keys) :
        instance_name => {
          target_id = module.app[instance_name].id
        }
      }
    }
  ]
}