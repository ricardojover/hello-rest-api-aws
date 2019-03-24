module "hello_database" {
  source = "github.com/ricardojover/hello-rest-api-aws/terraform/mysql"
  #source = "../mysql"

  cluster_name = "${var.cluster_name}"
  db_size = "${var.hello_db_size}"
  db_instance_class = "${var.hello_db_instance_class}"
  db_name = "${var.db_name}"
  db_user = "${var.db_user}"
  db_password = "${var.db_password}"
  subnets = "${module.hello_vpc.private_subnets}"
  vpc_id = "${module.hello_vpc.vpc_id}"
  allowed_security_groups = ["${aws_security_group.ecs_tasks.id}"]
}
