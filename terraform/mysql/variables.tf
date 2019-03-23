variable "vpc_id" {}
variable "cluster_name" {}
variable "db_size" {}
variable "db_instance_class" {}
variable "db_user" {}
variable "db_password" {}
variable "db_name" {} 
variable "allowed_security_groups" {
  type = "list"
}
variable "subnets" {
  type = "list"
}
