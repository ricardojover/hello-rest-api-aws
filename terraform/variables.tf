variable "region" { default = "eu-west-2" }
variable "vpc_cidr_block" { default = "10.0.0.0/16" }
variable "public-cidr" { 
  type = "list"
  default = ["10.0.0.0/24", "10.0.1.0/24"] 
}
variable "private-cidr" { 
  type = "list"
  default = ["10.0.10.0/24", "10.0.11.0/24"] 
}
variable "cluster_name" { default = "hello-cluster" }
variable "my_ips" { 
  type = "list"
}
variable "docker_account" { }
variable "docker_name" { }
variable "hello_tag" { } # e.g. 0.0.1
variable "hello_instance_tcp_port" { default = "8000" } 
variable "hello_container_tcp_port" { default = "8000" }
variable "hello_desired_count" { default = 2 }
variable "hello_family" { default = "hello-svc" }
variable "hello_db_size" { default = 20 }
variable "hello_db_instance_class" { default = "db.t2.micro" }

variable "db_user" { default = "hello" }
variable "db_password" { }
variable "db_name" { default = "hello" }
#variable "ssl_cert_arn" { }
variable "hello_service_cpu" { default = 256 }
variable "hello_service_memory" { default = 512 }
variable "fargate_hello_cpu" { default = 256 }
variable "fargate_hello_memory" { default = 512 }
