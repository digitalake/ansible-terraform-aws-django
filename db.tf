module "db" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = var.db_name

  instance_type          = var.db_instance_type
  ami                    = var.db_ami
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [module.db-sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[1]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = "db"
  }
}

module "db-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "db-sg"
  description = "Security group for the database instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app-sg.security_group_id
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