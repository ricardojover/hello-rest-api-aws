variable "my_ips" { 
  type = "list"
}
variable "cluster_name" { default = "hello-eks" }
variable "docker_account" {}
variable "docker_name" {}
variable "hello_tag" {}
variable "hello_instance_tcp_port" { default = "8000" } 
variable "hello_container_tcp_port" { default = "8000" }
variable "hello_desired_count" { default = 2 }
variable "hello_family" { default = "hello-svc" }
variable "hello_db_size" { default = 20 }
variable "hello_db_instance_class" { default = "db.t2.micro" }
variable "db_user" { default = "hello" }
variable "db_password" {}
variable "db_name" { default = "hello" }
#variable "ssl_cert_arn" {}
variable "hello_service_cpu_required" { default = "250m" }
variable "hello_service_memory_required" { default = "256Mi" }
variable "hello_service_cpu_limit" { default = "1" }
variable "hello_service_memory_limit" { default = "512Mi" }
