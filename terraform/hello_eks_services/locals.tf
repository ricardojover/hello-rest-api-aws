locals {
  cluster_name = "${data.terraform_remote_state.hello_eks.cluster_name}" 
  tags = {
    GitRepo = "github.com/ricardojover/hello-rest-api-aws"
  }
}
