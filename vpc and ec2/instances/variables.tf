//variable for infrastructure for remote state configuration
variable "region" {
  default = "us-east-2"
  description ="aws region"
}
variable "remote_state_bucket" {
  description = "bucket name for layer 1 remote state"
}
variable "remote_state_key" {
  description = "key for for layer 1 bucket name"
}
variable "ec2_instancetype" {
  description = "ec2-instance type to launch"
}
variable "key_pair_name" {
  default = "DevOPsAWs"
  description = "keypair for ec2"
}
variable "max_instance_size" {
  description = "Maximum number of instance EC2-instance "
}
variable "min_instance_size" {
  description = "Maximum number of instance EC2-instance "
}