resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${aws_vpc.main.id}"
  }
}

resource "aws_subnet" "eu-west-2a-public" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block = "${var.subnet-eu-west-2a-cidr}"
  availability_zone = "eu-west-2a"

  tags {
    Name = "hello-eu-west-2a-public"
  }
}

resource "aws_subnet" "eu-west-2b-public" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block = "${var.subnet-eu-west-2b-cidr}"
  availability_zone = "eu-west-2b"

  tags {
    Name = "hello-eu-west-2b-public"
  }
}

resource "aws_route_table" "eu-west-2a-public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "hello-eu-west-2a-public"
  }
}

resource "aws_route_table" "eu-west-2b-public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "hello-eu-west-2b-public"
  }
}

resource "aws_route_table_association" "eu-west-2a-public" {
  subnet_id = "${aws_subnet.eu-west-2a-public.id}"
  route_table_id = "${aws_route_table.eu-west-2a-public.id}"
}

resource "aws_route_table_association" "eu-west-2b-public" {
  subnet_id = "${aws_subnet.eu-west-2b-public.id}"
  route_table_id = "${aws_route_table.eu-west-2b-public.id}"
}