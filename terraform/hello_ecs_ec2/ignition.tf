data "ignition_config" "userdata" {
  systemd = ["${
    list(
      data.ignition_systemd_unit.docker_tcp_socket.id,
      data.ignition_systemd_unit.docker_cleanup_service.id,
      data.ignition_systemd_unit.ecs_agent_service.id,
    )}"
  ]
  files = [
    "${data.ignition_file.update_conf.id}",
  ]
}

data "ignition_file" "update_conf" {
  filesystem = "root"
  mode       = 420
  path       = "/etc/coreos/update.conf"

  content {
    content = "REBOOT_STRATEGY=\"off\""
  }

  uid = 0
}

data "ignition_systemd_unit" "docker_tcp_socket" {
  name    = "docker-tcp.socket"
  enabled = true
  content = "${file("${path.module}/userdata/systemd/docker-tcp.socket")}"
}

data "ignition_systemd_unit" "docker_cleanup_service" {
  name    = "docker-cleanup.service"
  enabled = true
  content = "${file("${path.module}/userdata/systemd/docker-cleanup.service")}"
}

data "ignition_systemd_unit" "ecs_agent_service" {
  name    = "ecs-agent.service"
  enabled = true
  content = "${file("${path.module}/userdata/systemd/ecs-agent.service")}"

  dropin = [{
    "name"    = "20-ecs_agent_service.conf"
    "content" = <<EOF
[Service]
Environment=cluster_name=${var.cluster_name}
EOF
  }]
}
