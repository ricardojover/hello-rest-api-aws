resource "aws_db_instance" "mysql" {
  depends_on             = ["aws_security_group.mysql"]
  identifier             = "${local.db_identifier}"
  allocated_storage      = "${var.db_size}"
  engine                 = "mysql"
  engine_version         = "8.0"
  multi_az               = true
  instance_class         = "${var.db_instance_class}"
  name                   = "${var.db_name}"
  username               = "${var.db_user}"
  password               = "${var.db_password}"
  vpc_security_group_ids = ["${aws_security_group.mysql.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.mysql.id}"
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${local.db_identifier}-db_subnet_group"
  subnet_ids = ["${var.subnets}"]
}

resource "aws_security_group" "mysql" {
  name   = "${local.db_identifier}_db_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${var.allowed_security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.db_identifier}_db_sg"
  }
}
