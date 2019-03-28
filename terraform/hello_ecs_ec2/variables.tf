variable "region" { default = "eu-west-2" }
variable "vpc_cidr_block" { default = "10.0.0.0/16" }
variable "subnet-eu-west-2a-cidr" { default = "10.0.0.0/24" }
variable "subnet-eu-west-2b-cidr" { default = "10.0.1.0/24" }
variable "cluster_name" { default = "hello-cluster" }
variable "health_check_type" { default = "EC2" }
variable "volume_size" { default = "10" }
variable "volume_type" { default = "gp2" }
variable "aws_autoscaling_group_desired" { default = "4" }
variable "aws_autoscaling_group_max" { default = "5" }
variable "aws_autoscaling_group_min" { default = "3" }
variable "instance_type" { default = "t2.medium" }
variable "key_name" { }
variable "my_ips" { 
  type = "list"
}
variable "hello_tag" { }
variable "hello_instance_tcp_port" { default = "80" }
variable "hello_container_tcp_port" { default = "8000" }
variable "hello_desired_count" { default = 2 }
variable "hello_family" { default = "hello-svc" }
variable "hello_db_size" { default = 20 }
variable "hello_db_instance_class" { default = "db.t2.micro" }
variable "db_user" { default = "hello" }
variable "db_password" { }
variable "db_name" { default = "hello" }


