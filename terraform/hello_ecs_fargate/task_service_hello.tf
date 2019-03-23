data "template_file" "hello" {
  template = "${file("${path.module}/tasks/hello.json.tmpl")}"

  vars {
    connection_string        = "${module.hello_database.connection_string}"
    hello_tag                = "${var.hello_tag}"
    hello_instance_tcp_port  = "${var.hello_instance_tcp_port}"
    hello_container_tcp_port = "${var.hello_container_tcp_port}"
    hello_service_memory     = "${var.hello_service_memory}"
    hello_service_cpu        = "${var.hello_service_cpu}"
    docker_account           = "${var.docker_account}"
    docker_name              = "${var.docker_name}"
  }
}

resource "aws_ecs_task_definition" "hello" {
  family                   = "${var.hello_family}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_hello_cpu}"
  memory                   = "${var.fargate_hello_memory}"
  container_definitions    = "${data.template_file.hello.rendered}"
}

resource "aws_ecs_service" "hello" {
  name            = "${var.hello_family}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.hello.arn}"
  launch_type     = "FARGATE"
  desired_count   = "${var.hello_desired_count}"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks.id}"]
    subnets         = ["${module.hello_vpc.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.hello_service.arn}"
    container_name   = "${var.hello_family}"
    container_port   = "${var.hello_container_tcp_port}"
  }

  depends_on = ["aws_lb_listener.hello_service"]
}

resource "aws_lb" "hello_service" {
  name               = "${var.cluster_name}-${var.hello_family}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.hello_service_external_access.id}"]
  subnets            = ["${module.hello_vpc.public_subnets}"]
}

resource "aws_lb_target_group" "hello_service" {
  name        = "${var.cluster_name}-${var.hello_family}"
  port        = "${var.hello_instance_tcp_port}"
  protocol    = "HTTP"
  vpc_id      = "${module.hello_vpc.vpc_id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/healthz"
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "hello_service" {
  load_balancer_arn = "${aws_lb.hello_service.arn}"
  port              = "80"
  protocol          = "HTTP"

  #port              = "443"
  #protocol          = "HTTPS"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "${var.ssl_cert_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.hello_service.arn}"
  }
}

resource "aws_security_group" "hello_service_external_access" {
  name   = "${var.cluster_name}-${var.hello_family}"
  vpc_id = "${module.hello_vpc.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ips}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
