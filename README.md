# <h1 align="center">Ansible + Terraform </a>

In this repo You can find the code to deploy the AWS infra with Terraform, configure created infra with Ansible.

### Infrastructure scheme. Terraform resources

![multienv (2)](https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/2fe60e2c-21d7-471e-9d0d-996777665e78)

The resource list (only general are mentioned):
  - EC2 application servers
  - EC2 Bastion host
  - EC2 Database server
  - Application Load Balancer
    - Target group
  - VPC:
    - NAT GW
    - Internet GW
    - Subnets
    - Route tables
  - Security groups

Several [Official Terraform modules](https://registry.terraform.io/browse/modules) were used.

Terraform outputs:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/bd3ccc1f-09f0-47d5-9f29-fb2cc03160aa" width="550">



### Terraform. Interacting with Ansible

Typicly for using Terraform together with ansible, such strategy is used:
- Terraform is used for creating infrastructure (Servers, LBs, Networking etc.)
- Ansible is used for configuration management (Installing necessary software, libs, modules, performing some tasks on the remote hosts)

To achive such cooperation between these tools, there are ususally 2 popular ways:
- using Ansible dynamic inventory (when using Ansible with AWS, ec2 plugin is required)
- generating Ansible inventory from the Terrafom outputs

In this particular task, the second way was used. The goal is to create Ansible inventory and some addtional configs from the Terraform go-templates which were prepared earlier. 

As you can see [here](https://github.com/digitalake/ansible-terraform-aws-django/tree/main/tftemplates), there are 3 templates with _.tftpl_ extension (which is the common extension for Terraform templates). Also, it's important to look at the _local_file_ resources [here](https://github.com/digitalake/ansible-terraform-aws-django/blob/main/artifacts.tf), where You can see the definitions for values will be inserted into the template during generating. Let's look at the logic of the _inventory.tftpl_ templatefile.

Template snippet:
```
[apps]
%{ for private_ip in app_ips ~}
${private_ip}
%{ endfor ~}
...
```

Terraform _local_file_ resource snippet:
```
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/tftemplates/inventory.tftpl",
    {
      ...
      app_ips    = [for instance in module.app : instance.private_ip]
    }
  )
  filename = "${path.module}/ansible/inventory"
}
```

The values from instances, created by the _app_ module will be inserted into the Ansible _[apps]_ hostgroup.

An example of generated _inventory_ file is:
```
[apps]
10.0.1.148
10.0.1.7

[databases]
10.0.2.53

[bastion]
3.238.144.103
```

Another task is to properly describe the way Ansible should access the app and the db hosts in private subnets. In our case, the Bastion host is used for ssh-proxyjumps and the custom ssh config is being generated. Let's look at the logic of the _jumconf.tftpl_ templatefile.

Template snippet:
```
%{ if length(bastion_ip) > 0 ~}
Host ${bastion_ip}
  IdentityFile ~/.ssh/virt
  User ubuntu
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host * !${bastion_ip}
  IdentityFile ~/.ssh/virt
  User ubuntu
  ProxyJump ${bastion_ip}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
%{ endif ~}
```
> [!IMPORTANT]
> There is no need to hardcode the _IdentityFile_ option, it can be also generated by Terraform based on input variables. In case the code was made for local executions, i had no need to add any complexity. 

The idea is to configure the direct connection to the Bastion host and at the same time instruct Ansible to perform connections to private subnet hosts via _ProxyJump_ (which is the Bastion Host).

An example of generated _jumpconf_ file is:
```
Host 3.238.144.103
  IdentityFile ~/.ssh/virt
  User ubuntu
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host * !3.238.144.103
  IdentityFile ~/.ssh/virt
  User ubuntu
  ProxyJump 3.238.144.103
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

### Django and Docker

On the Application side Docker was used for the deployment, the  Postgres Database was deployed directly on the EC2. The idea was to write the _Dockerfile_ and  build the Docker image for Django application. In case i needed to add the Nginx reverse proxy for forwarding from Load Balancer to the Application Server (80tcp-->8000tcp) i decided to use Docker-compose as the deploying method.

Dockerfile:
```
FROM python:3.8

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

WORKDIR /app

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

EXPOSE 8000

ENTRYPOINT ["/app/docker-entrypoint.sh"]
```

The docker-entrypoint.sh content:

```
#!/bin/bash
set -e

python manage.py makemigrations
python manage.py migrate

exec gunicorn mysite.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3
```

> From Gunicorn docs: ... we recommend (2 x $num_cores) + 1 as the number of workers to start off with.

After an image was built and tested locally, it was pushed to the Dockerhub.

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/1b4b3758-259e-420f-a20c-d9a4d02cd534" width="500">


For generating _docker-compose.yml_, the Jinja2 template was used and placed into the [deployment role's templates](https://github.com/digitalake/ansible-terraform-aws-django/blob/main/ansible/roles/django-deploy/templates/docker-compose.yml.j2)  
 
### Ansible. Ansible-galaxy roles

The recommended way to use Ansible roles is using standart Ansible-galaxy roles structure. The proper role template can be created with
```
ansible-galaxy init <rolename>
```

Project's [Ansible directory](https://github.com/digitalake/ansible-terraform-aws-django/tree/main/ansible) consists of 3 roles:

- Application servers configuration role (installs Docker and necessary modules)
- Database server configuration role (installs Postgres, makes changes to the Postgres configs)
- Deployment role for deploying the Application (generates necessary configurations, deploys Application with Nginx reverse proxy)

For dynamic database host configuration, Terraform also creates and additional vars file directly in the Deployment role's vars dir _/ansible/roles/django-deploy/vars/dbhost.yml_. This value is included to create the Database URL value for django app.

Necessary files for application deployment are:

- custom _nginx.conf_ which is sourced from _/files_ dir of the Deployment role
- _docker-compose.yml_  which is generated from template and includes values from _app.env_
- _app.env_ with env vars for Django application

I find hardcoding such sensetive values (_DB_NAME_,  _DB_USER_, _DB_PASSWORD_, _DOCKER_REGISTRY_USER_, _DOCKER_REGISTRY_PASSWORD_) a bad practice, so i pass those values while running Ansible as the extra variables. Also env vars can be used.

For running app servers configuration:
```
cd ansible
ansible-playbook \
	-i inventory \
	--ssh-extra-args='-F jumpconf' \
	prepare-appnodes.yml \
```


For running db configuration:
```
cd ansible
ansible-playbook \
	-i inventory \
	--ssh-extra-args='-F jumpconf' \
	-e "DB_NAME=<name>" \
	-e "DB_USER=<user>" \
	-e "DB_PASSWORD=<password>" \
	prepare-db.yml \
```

For running deployment:
```
cd ansible
ansible-playbook \
	-i inventory \
	--ssh-extra-args='-F jumpconf' \
	-e "DB_NAME=<name>" \
	-e "DB_USER=<user>" \
	-e "DB_PASSWORD=<password>" \
	-e "DOCKER_REGISTRY_USER=<user>" \
	-e "DOCKER_REGISTRY_PASSWORD=<password>" \
	deploy-application.yml \
```
> [!IMPORTANT]
> Its important to use the same _DB_NAME_, _DB_USER_, _DB_PASSWORD_ values when running _prepare-db.yml_ and _deploy-application.yml_ because values from DB configuration are used by Application. 

### Results

Containers running on the app host:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/51154762-2879-4dbb-8f00-e50dd7da2567" width="600">

Django on ALB endpoint:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/85a680fe-5160-4af4-836e-28d646f6532f" width="600">

Application logs:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/d114c18a-9e77-44ec-8e49-d3302283609d" width="500">

Database logs:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/af084f69-5aa6-4f8e-ade3-ea9fdcb8ff1b" width="600">

Nginx logs:

<img src="https://github.com/digitalake/ansible-terraform-aws-django/assets/109740456/5f65f50c-76fe-4a28-800b-e1d8336a6a64" width="600">




 
