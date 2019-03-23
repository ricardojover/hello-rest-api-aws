terraform {
  required_version = ">= 0.11.13"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}"

  lifecycle {
    create_before_destroy = true
  }
}

module "hello_database" {
  #source = "github.com/ricardojover/hello-rest-api-aws/mysql"
  source = "../mysql"

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

resource "aws_security_group" "ecs_tasks" {
  name   = "${aws_ecs_cluster.main.name}"
  vpc_id = "${module.hello_vpc.vpc_id}"

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = "${var.hello_instance_tcp_port}"
    to_port         = "${var.hello_instance_tcp_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.hello_service_external_access.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${aws_ecs_cluster.main.name}-tasks"
  }
}
