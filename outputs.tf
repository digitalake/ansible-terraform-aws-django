output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "application_private_ips" {
  value = { for key, instance in module.app : "${key} with role=${instance.tags_all.Role}" => instance.private_ip }
}

output "database_private_ip" {
  value = module.db.private_ip
}

output "load_balancer_dns" {
  value = module.alb.lb_dns_name
}