resource "aws_db_instance" "hello" {
  depends_on             = ["aws_security_group.hello_db"]
  identifier             = "${var.cluster_name}-${var.db_name}"
  allocated_storage      = "${var.hello_db_size}"
  engine                 = "mysql"
  engine_version         = "8.0"
  multi_az               = true
  instance_class         = "${var.hello_db_instance_class}"
  name                   = "${var.db_name}"
  username               = "${var.db_user}"
  password               = "${var.db_password}"
  vpc_security_group_ids = ["${aws_security_group.hello_db.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.hello_db.id}"
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "hello_db" {
  name       = "hello_db_subnet_group"
  subnet_ids = ["${module.hello_vpc.private_subnets}"]
}

resource "aws_security_group" "hello_db" {
  name   = "hello_db_sg"
  vpc_id = "${module.hello_vpc.vpc_id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_tasks.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hello_db_sg"
  }
}
