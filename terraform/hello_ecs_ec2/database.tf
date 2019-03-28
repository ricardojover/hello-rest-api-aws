module "hello_database" {
  source = "github.com/ricardojover/hello-rest-api-aws/terraform/mysql"

  cluster_name = "${var.cluster_name}"
  db_size = "${var.hello_db_size}"
  db_instance_class = "${var.hello_db_instance_class}"
  db_name = "${var.db_name}"
  db_user = "${var.db_user}"
  db_password = "${var.db_password}"
  subnets = ["${aws_subnet.eu-west-2a-public.id}", "${aws_subnet.eu-west-2b-public.id}"]
  vpc_id = "${aws_vpc.main.id}"
  allowed_security_groups = ["${aws_security_group.ecs_host.id}"]
}
