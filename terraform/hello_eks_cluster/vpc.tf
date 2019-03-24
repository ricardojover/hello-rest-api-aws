data "aws_availability_zones" "available" {}

module "hello_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "hello_vpc_eks"
  cidr = "${var.vpc_cidr_block}"

  azs             = ["${data.aws_availability_zones.available.names}"]
  public_subnets  = "${var.public-cidr}"
  private_subnets = "${var.private-cidr}"

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = "${merge(local.tags, map("kubernetes.io/cluster/${var.cluster_name}", "shared"))}"
}
