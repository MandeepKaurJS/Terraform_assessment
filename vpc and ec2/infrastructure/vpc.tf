provider "aws" {
    region = "${var.region}"
}

terraform {
    backend "s3" {}
}
//creating aws_vpc resource
resource "aws_vpc" "production_vpc" {
    cidr_block           ="${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags =  {
        Name= "production_vpc"
    }

}
//associating subnets for public subnets
resource "aws_subnet" "subnet1" {
    cidr_block = "${var.subnet_cidr_1}"
    
    vpc_id     = "${aws_vpc.production_vpc.id}"
    
    availability_zone = "us-east-2a"
    tags ={
        Name ="Subnet1"
    }
}

resource "aws_subnet" "subnet2" {
    cidr_block ="${var.subnet_cidr_2}"
    
    vpc_id     ="${aws_vpc.production_vpc.id}"
    
    availability_zone = "us-east-2b"
    tags = {
        "Name"="Subnet2"
    }
}
//creating a route table for private routes
resource "aws_subnet" "private_subnet1" {
    cidr_block = "${var.private_subnet_cidr_1}"
    vpc_id     = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-2c"

    tags ={
        Name="private_subnet1"
    }
}
resource "aws_subnet" "private_subnet2" {
    cidr_block = "${var.private_subnet_cidr_2}"
    vpc_id     = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-2a"

    tags ={
        Name="private_subnet2"
    }
}
//creating public route table
resource "aws_route_table" "Production_route_table" {
    vpc_id = "${aws_vpc.production_vpc.id}"
    tags ={
        Name="public route table"
    }
}
//creating route table
resource "aws_route_table" "private_route_table" {
    vpc_id = "${aws_vpc.production_vpc.id}"
    tags ={
        Name="Private route table"
    }
}

//associating public route table with subnets
resource "aws_route_table_association" "aws_subnet1_association" {
    route_table_id = "${aws_route_table.Production_route_table.id}"
    subnet_id      = "${aws_subnet.subnet1.id}"
}

resource "aws_route_table_association" "aws_subnet2_association" {
    route_table_id = "${aws_route_table.Production_route_table.id}"
    subnet_id      = "${aws_subnet.subnet2.id}"
}
//associating private table with subnets
resource "aws_route_table_association" "aws_privatesubnet1_association" {
    route_table_id = "${aws_route_table.private_route_table.id}"
    subnet_id      = "${aws_subnet.private_subnet1.id}"
}
resource "aws_route_table_association" "aws_privatesubnet2_association" {
    route_table_id = "${aws_route_table.private_route_table.id}"
    subnet_id      = "${aws_subnet.private_subnet2.id}"
}
//creating elastic ip for NAT Gateway
resource "aws_eip" "elastic_ip_for_natgw" {
    vpc = true
    associate_with_private_ip = "10.0.0.5"
//    tags {
//        Name = "Production_ip"
//    }
}

resource "aws_nat_gateway" "natgateway" {
    allocation_id = "${aws_eip.elastic_ip_for_natgw.id}"
    subnet_id     = "${aws_subnet.subnet1.id}"
    tags ={
        Name = "Production NATGatway"
    }
    depends_on = [aws_eip.elastic_ip_for_natgw]
}
resource "aws_route" "natgateway_route" {
    route_table_id = "${aws_route_table.private_route_table.id}"
    nat_gateway_id = "${aws_nat_gateway.natgateway.id}"
    destination_cidr_block = "0.0.0.0/0"
}
//Create an internet Gateway and adding to route table
resource "aws_internet_gateway" "production_igw" {
    vpc_id = "${aws_vpc.production_vpc.id}"
    tags ={
        Name="production_iGW"
    }
}
resource "aws_route" "public_internetGW" {
    route_table_id = "${aws_route_table.Production_route_table.id}"
    gateway_id     = "${aws_internet_gateway.production_igw.id}"
    destination_cidr_block = "0.0.0.0/0"
}