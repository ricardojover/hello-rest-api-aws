module "eks" {
  source                = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name          = "${var.cluster_name}"
  subnets               = ["${module.hello_vpc.private_subnets}"]
  vpc_id                = "${module.hello_vpc.vpc_id}"
  config_output_path    = "./"
  write_kubeconfig      = "true"
  write_aws_auth_config = "true"

  worker_groups = [
    {
      instance_type        = "t2.small"
      subnets              = "${join(",", module.hello_vpc.private_subnets)}"
      asg_desired_capacity = "2"
      asg_max_size         = "5"
      asg_min_size         = "2"
    }
  ]

  tags = "${merge(local.tags, map("Name", "${var.cluster_name}"))}"
}

resource "null_resource" "update_kube_config" {
  depends_on = ["module.eks"]

  provisioner "local-exec" {
    command = "CLUSTER_ARN=`aws eks update-kubeconfig --name ${var.cluster_name} | awk -F' ' '{print $3}'` && kubectl config use-context $CLUSTER_ARN"
  }
}

