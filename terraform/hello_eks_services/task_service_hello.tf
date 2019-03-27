resource "kubernetes_service" "hello_lb" {
  metadata {
    name = "${var.cluster_name}-${var.hello_family}"
  }
  spec {
    selector {
      app = "${kubernetes_deployment.hello.metadata.0.labels.app}"
    }

    port {
      name = "http"
      port = "80"
      target_port = "${var.hello_container_tcp_port}"
    }

    load_balancer_source_ranges = ["${var.my_ips}"]

    type = "LoadBalancer"
  }
}

# If you want to enable HTTPS in your LB add the following lines to the kubectl command bellow
# And replace the values http and 80 with https and 443 respectively in the hello_lb resource above
#   'service.beta.kubernetes.io/aws-load-balancer-ssl-cert=${var.ssl_cert_arn}' \
#   'service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy=ELBSecurityPolicy-TLS-1-2-2017-01' \
resource "null_resource" "hello_lb_metadata_annotations" {
  depends_on = ["kubernetes_service.hello_lb"]

  provisioner "local-exec" {
    command = <<EOF
kubectl annotate --overwrite --namespace ${kubernetes_service.hello_lb.metadata.0.namespace} \
  service ${kubernetes_service.hello_lb.metadata.0.name} \
  'service.beta.kubernetes.io/aws-load-balancer-backend-protocol=http' \
  'service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled=true' \
  'service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled=true' \
  'service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold=2' \
  'service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold=3' \
  'service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval=20' \
  'service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout=3' \
EOF
  }
}

resource "kubernetes_deployment" "hello" {
  depends_on = ["module.hello_database", "data.terraform_remote_state.hello_eks"]

  metadata {
    name = "${var.cluster_name}-${var.hello_family}"
    namespace = "default"

    labels {
      app = "${var.cluster_name}-${var.hello_family}"
      cluster_name = "${var.cluster_name}"
    }
  }

  spec {
    replicas = "${var.hello_desired_count}"

    selector {
      match_labels {
        app = "${var.cluster_name}-${var.hello_family}"
      }
    }

    template {
      metadata {
        labels {
          app = "${var.cluster_name}-${var.hello_family}"
          cluster_name = "${var.cluster_name}"
          servicename = "hello"
        }
      }

      spec {
        container {
          image = "${var.docker_account}/${var.docker_name}:${var.hello_tag}"
          name  = "hello"
          port = [{
            container_port = "${var.hello_container_tcp_port}"
            protocol = "TCP"
          }]
          env = [
            {
              name = "CONNECTION_STRING"
              value = "${module.hello_database.connection_string}"
            },
            {
              name = "VERSION"
              value = "${var.hello_tag}"
            },
            {
              name = "ENV"
              value = "${var.env}"
            }
          ]

          resources {
            limits {
              memory = "${var.hello_service_memory_limit}"
              cpu    = "${var.hello_service_cpu_limit}"
            }
            requests {
              memory = "${var.hello_service_memory_required}"
              cpu    = "${var.hello_service_cpu_required}"
            }
          }

          liveness_probe {
            http_get {
              scheme = "HTTP"
              path = "/healthz"
              port = "${var.hello_container_tcp_port}"
            }
            initial_delay_seconds = "30"
            period_seconds = "30"
          } 
        }
      }
    }
  }
}

