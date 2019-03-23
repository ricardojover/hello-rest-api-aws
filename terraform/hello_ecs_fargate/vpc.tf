module "hello_vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "hello_vpc_fargate"
  cidr = "${var.vpc_cidr_block}"

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = "${var.public-cidr}"
  private_subnets = "${var.private-cidr}"
  
  enable_nat_gateway = true
  single_nat_gateway = true
}