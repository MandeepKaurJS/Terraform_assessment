# Terraform_assessment
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
- I implement our Auto-Scaling Groups usinge launch configurations. We will configure the subnets, machine images, startup scripts and simply everything 
we need to launch instances successfully.
- I created subnet_group and replication_group for creating Elasticache and associate them to private subnet on VPC


| Command | Description |
| --- | --- |
| `terraform plan` | List all *new or modified* provisioned resourses |
| `terraform apply` | Will create all the resourses on top of AWS cloud |
