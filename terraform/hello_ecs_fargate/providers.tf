provider "aws" {
  region = "${var.region}"
  version = "= 2.3"
}

provider "null" {
  version = "= 2.1"
}

provider "template" {
  version = "= 2.1"
}
