# Terraform_assessment

- Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom 
in-house solutions.
# Prerequisites
To follow this tutorial you will need:

1. The Terraform CLI (0.14.9+) installed.
2. The AWS CLI installed.
3. An AWS account.
4. Your AWS credentials. I created a user in AWS to get the autentication through secret and access key.
- I Configure the AWS CLI from terminal. By using below command to input your AWS Access Key ID and Secret Access Key.
```
aws configure
```
- I created set of files used to describe infrastructure in Terraform is known as a Terraform configuration as well as variable files describing the values of resourses.
Also created the *outputs.tf* files to get the *outputs* of resources like their Ids, Name etc. 
# Example
```
variable.tf
example.tffvars
outputs.tf
```
- I am starting with implementing our remote state and obtaining a key pair which I used to connect to the instances we will launch. 
Once I get these done, I created the Virtual Private Cloud (VPC) environment. I also write the terraform script for the public and private subnet.
See the below script for subnet provisioning
```
resource "aws_subnet" "subnet1" {
    cidr_block = var.subnet_cidr_1
    
    vpc_id     = aws_vpc.production_vpc.id
    
    availability_zone = "us-east-2a"
    tags ={
        Name ="Subnet1"
    }
}
```
- I attach an Internet Gateway (IGW) to our VPC to use with public subnets so the resources in those will be able to access and receive public internet traffic. 
Our private subnet also needs some form of internet connection but not both ways; we want only internet access for outgoing connections from our resources in private subnets! 
To satisfy this requirement, we will launch and attach a NAT Gateway to our private route table.

The below script will show you how we can provision NAT Gateways
```
resource "aws_nat_gateway" "natgateway" {
    allocation_id = aws_eip.elastic_ip_for_natgw.id
    subnet_id     = aws_subnet.subnet1.id
    tags ={
        Name = "Production NATGatway"
    }
    depends_on = [aws_eip.elastic_ip_for_natgw]
}
```
- I implemented Auto-Scaling Groups using launch configurations. We will configure the subnets, machine images, startup scripts and simply everything 
we need to launch instances successfully.
- I created private backend EC2 instances. If someone wants to create a backend using the Elastic compute service of AWS which is optional. It is optional I commented 
it if you want to make it work uncomment it. 

# Elastic Cache Association inside VPC
- I created subnet_group and replication_group for creating Elasticache and associate them to private subnet on VPC. I used this configuration in order to acheive this:
```
resource "aws_elasticache_subnet_group" "private_subnet_group" {
    name       = "tf-test-cache-subnet"
    subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}
//creating replication group for elastic cache

resource "aws_elasticache_replication_group" "relication_group" {
    replication_group_id          = var.cluster_id
    replication_group_description = "Redis cluster for Hashicorp ElastiCache example"

    node_type            = "cache.t2.small"
    port                 = 6379
    parameter_group_name = "default.redis3.2.cluster.on"

    snapshot_retention_limit = 5
    snapshot_window          = "00:00-05:00"

    subnet_group_name          = aws_elasticache_subnet_group.your_private_subnet.name
    automatic_failover_enabled = true

    cluster_mode {
        replicas_per_node_group = 1
        num_node_groups         = var.node_groups
    }
}
```

- When you create a new configuration — or check out an existing configuration from version control — We need to initialize the directory with terraform init.
  Initializing a configuration directory downloads and installs the providers defined in the configuration, which in this case is the aws provider.
- terraform plan- creates an execution plan. By default, creating a plan consists of:
   1. Reading the current state of any already-existing remote objects to make sure that the Terraform state is up-to-date.
   2. Comparing the current configuration to the prior state and noting any differences.
   3. Proposing a set of change actions that should, if applied, make the remote objects match the configuration.

- The terraform appply command executes the actions proposed in a Terraform plan.
- I used these commands to provision the infrastructure on top of AWS Cloud. 
| Command | Description |
| --- | --- |
| `terraform init` | To initlize the directory |
| `terraform plan` | List all *new or modified* provisioned resourses |
| `terraform apply` | Will create all the resourses on top of AWS cloud |
| `terraform destroy` | Will cleanup everything which we created |
