resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/tftemplates/inventory.tftpl",
    {
      db_ip      = module.db.private_ip
      bastion_ip = module.bastion.public_ip
      app_ips    = [for instance in module.app : instance.private_ip]
    }
  )
  filename = "${path.module}/ansible/inventory"
}

resource "local_file" "ansible_jumpconf" {
  content = templatefile("${path.module}/tftemplates/jumpconf.tftpl",
    {
      bastion_ip = module.bastion.public_ip
    }
  )
  filename = "${path.module}/ansible/jumpconf"
}

resource "local_file" "ansible_db_host" {
  content = templatefile("${path.module}/tftemplates/dbhost.tftpl",
    {
      db_ip = module.db.private_ip
    }
  )
  filename = "${path.module}/ansible/roles/django-deploy/vars/dbhost.yml"
}
