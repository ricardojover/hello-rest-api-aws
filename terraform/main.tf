resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}"

  lifecycle {
    create_before_destroy = true
  }
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
