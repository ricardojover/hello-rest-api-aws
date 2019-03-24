module "hello_database" {
  source = "github.com/ricardojover/hello-rest-api-aws/terraform/mysql"

  cluster_name = "${var.cluster_name}"
  db_size = "${var.hello_db_size}"
  db_instance_class = "${var.hello_db_instance_class}"
  db_name = "${var.db_name}"
  db_user = "${var.db_user}"
  db_password = "${var.db_password}"
  subnets = "${data.terraform_remote_state.hello_eks.private_subnets}"
  vpc_id = "${data.terraform_remote_state.hello_eks.vpc_id}"
  allowed_security_groups = ["${data.terraform_remote_state.hello_eks.eks_workers_security_group_id}"]
}
