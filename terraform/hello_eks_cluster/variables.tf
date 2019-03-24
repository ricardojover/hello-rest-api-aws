variable "cluster_name" { default = "hello-eks" }
variable "region" { default = "eu-west-2" }
variable "vpc_cidr_block" { default = "10.1.0.0/16" }
variable "public-cidr" { 
  type = "list"
  default = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"] 
}
variable "private-cidr" { 
  type = "list"
  default = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"] 
}

