provider aws {
  region = "${data.terraform_remote_state.hello_eks.region}"
  version = "= 2.3"
}

provider kubernetes {
  version = "= 1.5"
}

provider null {
  version = "= 2.1"
} 