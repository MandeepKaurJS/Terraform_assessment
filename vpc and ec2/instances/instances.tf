provider "aws" {
  region = var.region
}
terraform {
  backend "s3" {}
}
//defining backend and reading remote state for layer 1 infrastructure
data "terraform_remote_state" "network_configuration" {
  backend = "s3"
  config ={
    bucket = var.remote_state_bucket
    key = var.remote_state_key
    region = var.region
  }
}
//creating secrurity groups for ec2 instances
resource "aws_security_group" "public_security_group" {
  name ="EC2-public-SG"
  description = "internet reacheing access for EC2 instances"
  vpc_id = data.terraform_remote_state.network_configuration.vpc_id.id
  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = ["98.247.76.81"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "EC2_private_SG" {
  name = "EC2-private-SG"
  description = "only allow public security group resources to access these EC2"
  vpc_id = data.terraform_remote_state.network_configuration.vpc_id
  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = [
      aws_security_group.public_security_group.id]
  }
  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow health checking for instance to using this instance group"
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "elb_SG" {
  name = "ELB Securrity group"
  description = "ELB security group"
  vpc_id = data.terraform_remote_state.network_configuration.vpc_id
  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow web traffice to ELB"
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
//creating IAM roles for EC2 instances
resource "aws_iam_role" "ec2_iam_role" {
  name               = "EC2_IAM_policy"
  assume_role_policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" :
  [
    {
      "Effect" : "Allow",
      "Prinicipal" : {
        "Service" : ["ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
      },
      "Action" : "sts:AssumeRole"
    }
  ]
}
EOF
}
//creating an IAM role policy for ec2 instances
resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name = "EC2_IAM_Role_Policy"
  role = aws_iam_role.ec2_iam_role.id
  policy = <<-EOF
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
            "ec2:*",
            "elasticloadbalancing:*",
            "cloudwatch:*",
            "logs:*"
        ],
        "Resource" : "*"
      }
    ]
  }
  EOF
}
//creating and IAM instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-IAM-Profile"
  role = aws_iam_role.ec2_iam_role.name
}
//dynamically using latest ami for ec2 instance
data "aws_ami" "Launch_config_file" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
}
//launch configuration for private ec2 instance
resource "aws_launch_configuration" "private_ec2_config" {
  image_id               = "ami-03657b56516ab7912"
  instance_type          = var.ec2_instancetype
  key_name               = var.key_pair_name
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups       =  [
    aws_security_group.EC2_private_SG.id]
  user_data = <<EOF
      #!/bin/bash
      yum update -y
      yum install httpd -y
      service httpd start
      chkconfig httpd on
      export INSTANCE_ID=$(curl http://169.254.169.254/latest/metad-ata/instance-id)
      echo"<html><body><h1>hello from mandeep backend at instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
  EOF
}
//launch configuration for private ec2 instance
resource "aws_launch_configuration" "public_ec2_cconfig" {
  //image_id                    = "${data.aws_ami.Launch_config_file.id}"
  image_id                    = "ami-03657b56516ab7912"
  instance_type               = var.ec2_instancetype
  key_name                    = var.key_pair_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = [
    aws_security_group.public_security_group.id]

  user_data = <<EOF
      #!/bin/bash
      yum update -y
      yum install httpd24 -y
      service httpd start
      chkconfig httpd on
      export INSTANCE_ID=$(curl http://169.254.169.254/latest/metad-ata/instance-id)
      echo"<html><body><h1>hello from mandeep webapp at instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
  EOF
}
//creating load balancer for public webapp tier
resource "aws_elb" "webapp_load_balancer" {
  name = "Production-webapp"
  internal = true
  security_groups = [
    aws_security_group.elb_SG.id]
  subnets = [
    data.terraform_remote_state.network_configuration.public_subnet1_id,
    data.terraform_remote_state.network_configuration.public_subnet2_id
  ]
  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }
  health_check {
    healthy_threshold = 5
    interval = 30
    target = "HTTP:80/index.html"
    timeout = 10
    unhealthy_threshold = 5
  }
}
//creating load balancer for private webapp tier backend
resource "aws_elb" "backend_load_balancer" {
  name = "Backend-load-balancer"
  internal = true
  security_groups = [
    aws_security_group.elb_SG.id]
  subnets = [
    data.terraform_remote_state.network_configuration.private_subnet1_id,
    data.terraform_remote_state.network_configuration.private_subnet2_id
  ]
  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }
  health_check {
    healthy_threshold = 5
    interval = 30
    target = "HTTP:80/index.html"
    timeout = 10
    unhealthy_threshold = 5
  }
}
//creating an autoscaling group for private ec2 instance
resource "aws_autoscaling_group" "ec2_private_autoSG" {
  name                = "Production backend AUTOSG"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_configuration.private_subnet1_id,
    data.terraform_remote_state.network_configuration.private_subnet2_id
  ]
  max_size            = var.max_instance_size
  min_size            = var.min_instance_size
  launch_configuration = aws_launch_configuration.private_ec2_config.name
  health_check_type = "ELB"
  load_balancers = [
    aws_elb.backend_load_balancer.name]
  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "Backend-EC2-Instances"
  }
  tag {
    key = "Type"
    propagate_at_launch = false
    value = "Production-Backend"
  }
}
//creating an autoscaling group for public ec2 instance
resource "aws_autoscaling_group" "ec2_public_autoSG" {
  name = "Production-webapp-autoSG"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_configuration.public_subnet1_id,
    data.terraform_remote_state.network_configuration.public_subnet2_id
  ]
  max_size = var.min_instance_size
  min_size = var.min_instance_size
  launch_configuration = aws_launch_configuration.public_ec2_cconfig.name
  health_check_type = "ELB"
  load_balancers = [
    aws_elb.webapp_load_balancer.name]
  tag {
    key = "Name"
    propagate_at_launch = false
    value = "Production-webapp-ec2"
  }
  tag {
    key = "Type"
    propagate_at_launch = false
    value = "Production-Webapp"
  }
}
//creating autoscaling policy for public ec2 instance
resource "aws_autoscaling_policy" "webapp_production_scallingpolicy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_public_autoSG.name
  name = "Production-webapp-autoscalling-policy"
  policy_type = "TargetTrackingScaling"
  min_adjustment_magnitude = 1
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtiliztion"
    }
    target_value = 80.0
  }
}
//creating autoscaling policy for private ec2 instance
resource "aws_autoscaling_policy" "backend_production_Scalingpolicy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_private_autoSG
  name = "Production-backend-autoscalingpolicy"
  policy_type = "TargetTrackingScaling"
  min_adjustment_magnitude = 1
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtiliztion"
    }
    target_value = 80.0
  }
}
//creating SNS topic for auto scaling notification
resource "aws_sns_topic" "webapp_production_autoscalig_topicAlert" {
  display_name = "Webapp-AutoScaling-Topic"
  name = "Webapp-AutoScaling-Topic"
}
//creating SNS subscription for Sms to receive auto scalingnotification
resource "aws_sns_topic_subscription" "webapp_prodution_autoscaling_sns_subcription" {
  endpoint = "+2532176106"
  protocol = "sms"
  topic_arn = aws_sns_topic.webapp_production_autoscalig_topicAlert
}
//defining autoscaling notification for triggering on certain events
resource "aws_autoscaling_notification" "webapp_autoscaling_notification" {
  group_names = [
    aws_autoscaling_group.ec2_public_autoSG.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR"
  ]
  topic_arn = aws_sns_topic.webapp_production_autoscalig_topicAlert.arn
}
