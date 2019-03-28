resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "coreos_ami" {
  most_recent = true
  filter { name = "architecture" values = ["x86_64"] }
  filter { name = "root-device-type" values = ["ebs"] }
  filter { name = "name" values = ["CoreOS-stable-1967.6.0-hvm"] }
  owners = ["595879546273"]
}

resource "aws_launch_configuration" "hello_cluster" {
  image_id                    = "${data.aws_ami.coreos_ami.id}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.ecs_host.id}"]

  user_data                   = "${data.ignition_config.userdata.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.hello_ecs.id}"
  name_prefix                 = "${var.cluster_name}_lc"

  root_block_device {
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hello_cluster" {
  name                      = "${var.cluster_name}_asg"
  launch_configuration      = "${aws_launch_configuration.hello_cluster.name}"
  vpc_zone_identifier       = [ "${aws_subnet.eu-west-2a-public.id}", "${aws_subnet.eu-west-2b-public.id}" ]
  min_size                  = "${var.aws_autoscaling_group_min}"
  max_size                  = "${var.aws_autoscaling_group_max}"
  desired_capacity          = "${var.aws_autoscaling_group_desired}"
  health_check_grace_period = 300
  health_check_type         = "${var.health_check_type}"
  force_delete              = true
  suspended_processes       = ["AZRebalance"]

  tag {
    key                 = "Info"
    value               = "Hello"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-host"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    # ignore_changes        = ["desired_capacity","max_capacity","min_capacity"]
  }
}

resource "aws_iam_instance_profile" "hello_ecs" {
  name = "${var.cluster_name}_role"
  role = "${aws_iam_role.hello_ecs.name}"
}

resource "aws_security_group" "ecs_host" {
  name        = "${aws_ecs_cluster.main.name}"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port       = "${var.hello_instance_tcp_port}"
    to_port         = "${var.hello_instance_tcp_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.hello_service.id}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.my_ips}"
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
    Name = "${aws_ecs_cluster.main.name}-host"
  }
}
