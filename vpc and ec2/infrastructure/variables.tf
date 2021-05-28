
variable "region" {
    default = "us-east-2"
    description ="aws region"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description ="aws vpc"
}
variable "private_subnet_cidr_1" {
    description = "Private subnet 1"
}
variable "private_subnet_cidr_2" {
    description = "Private subnet 2"
}
variable "subnet_cidr_1" {
    description = "Public subnet 1"
}

variable "subnet_cidr_2" {
    description = "Public subnet 1"
}
