data "template_file" "hello" {
  template = "${file("${path.module}/tasks/hello.json.tmpl")}"

  vars {
    connection_string        = "${module.hello_database.connection_string}"
    hello_tag                = "${var.hello_tag}"
    hello_instance_tcp_port  = "${var.hello_instance_tcp_port}"
    hello_container_tcp_port = "${var.hello_container_tcp_port}"
  }
}

resource "aws_ecs_task_definition" "hello" {
  family                = "${var.hello_family}"
  container_definitions = "${data.template_file.hello.rendered}"
}


data "aws_ecs_task_definition" "hello" {
  depends_on = ["aws_ecs_task_definition.hello"]
  task_definition = "${aws_ecs_task_definition.hello.family}"
}

resource "aws_ecs_service" "hello" {
  name            = "${var.hello_family}"
  cluster         = "${var.cluster_name}"
  task_definition = "${aws_ecs_task_definition.hello.family}:${aws_ecs_task_definition.hello.revision}"
  #task_definition = "${aws_ecs_task_definition.hello.family}:${max("${aws_ecs_task_definition.hello.revision}", "${data.aws_ecs_task_definition.hello.revision}")}"

  desired_count   = "${var.hello_desired_count}"
  iam_role        = "${aws_iam_instance_profile.hello_ecs.id}"

  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = "${aws_lb_target_group.hello_service.arn}"
    container_name   = "${var.hello_family}"
    container_port   = "${var.hello_container_tcp_port}"
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

resource "aws_lb" "hello_service" {
  name               = "${var.cluster_name}-${var.hello_family}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.hello_service.id}"]
  subnets            = ["${aws_subnet.eu-west-2a-public.id}", "${aws_subnet.eu-west-2b-public.id}"]
}

resource "aws_lb_target_group" "hello_service" {
  name     = "${var.cluster_name}-${var.hello_family}"
  port     = "${var.hello_instance_tcp_port}"
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  deregistration_delay = 60

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/healthz"
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_autoscaling_attachment" "hello_cluster_asg_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.hello_cluster.id}"
  alb_target_group_arn   = "${aws_lb_target_group.hello_service.arn}"
}

resource "aws_lb_listener" "hello_service" {
  load_balancer_arn = "${aws_lb.hello_service.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.hello_service.arn}"
  }
}

resource "aws_security_group" "hello_service" {
  name        = "${var.cluster_name}-${var.hello_family}"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ips}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-${var.hello_family}"
  }
}
