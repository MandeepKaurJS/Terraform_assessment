output "lb_address" {
  value = aws_elb.backend_load_balancer.id
}

//ssh host name
output "ssh_host" {
  value = "${aws_launch_configuration.public_ec2_cconfig.id}"
}