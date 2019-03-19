data "template_file" "tests" {
  template = "${file("${path.module}/scripts/test-rest-api.sh.tmpl")}"

  vars {
    endpoint = "${aws_lb.hello_service.dns_name}"
    version  = "${var.hello_tag}"
  }
}

resource "null_resource" "create_test_script" {
  #depends_on = ["null_resource.endpoint_to_be_ready"]

  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.tests.rendered}")}"
  }

  provisioner "local-exec" {
    command = "cat <<EOF>test-rest-api.sh\n${data.template_file.tests.rendered}\nEOF"
  }
}

resource "null_resource" "run_tests" {
  depends_on = ["null_resource.create_test_script"]

  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.tests.rendered}")}"
  }

  provisioner "local-exec" {
    command = "chmod +x test-rest-api.sh && ./test-rest-api.sh"
  }
}

