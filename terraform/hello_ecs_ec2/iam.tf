resource "aws_iam_role" "hello_ecs" {
  name = "${var.cluster_name}_role"
  assume_role_policy = <<EOF
{ 
  "Version": "2012-10-17",
  "Statement": [
    { 
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    { 
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "hello_ecs" {
  name = "${var.cluster_name}_policy"
  role = "${aws_iam_role.hello_ecs.id}"
  policy = <<EOF
{ 
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DescribeClusters",
        "ecs:DescribeContainerInstances",
        "ecs:DiscoverPollEndpoint",
        "ecs:ListClusters",
        "ecs:ListContainerInstances",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}