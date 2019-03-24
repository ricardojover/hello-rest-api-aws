data "terraform_remote_state" "hello_eks" {
  backend = "local" 
  
  config = {
    path = "${path.module}/../hello_eks_cluster/terraform.tfstate"
  }
}

