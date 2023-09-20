module "app" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  for_each = toset(var.app_instance_keys)

  name = each.key

  instance_type          = var.app_instance_type
  ami                    = var.app_ami
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [module.app-sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = "app"
  }
}

module "app-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "app-sg"
  description = "Security group for the application instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.bastion-sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}