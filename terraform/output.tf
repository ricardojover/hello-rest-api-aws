output "hello_svc_dns_name" {
  value = "${aws_lb.hello_service.dns_name}"
}
