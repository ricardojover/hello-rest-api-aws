output "private_subnets" { value = "${module.hello_vpc.private_subnets}" }
output "vpc_id" { value = "${module.hello_vpc.vpc_id}" }
output "cluster_name" { value = "${module.eks.cluster_id}" }
output "region" { value = "${var.region}" }
output "eks_cluster_security_group_id" { value = "${module.eks.cluster_security_group_id}" }
output "eks_workers_security_group_id" { value = "${module.eks.worker_security_group_id}" }
