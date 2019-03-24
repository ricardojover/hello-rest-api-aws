## Must know
To deploy the k8s manifests we can do it with terraform resources or using directly the kubectl command against the YAML manifests.

At the time of writing, there is a limitation in the [Terraform's Kubernetes provider](https://www.terraform.io/docs/providers/kubernetes/guides/getting-started.html) as per bellow:
*There are at least 2 steps involved in scheduling your first container on a Kubernetes cluster. You need the Kubernetes cluster with all its components running somewhere and then schedule the Kubernetes resources, like Pods, Replication Controllers, Services etc.*

This is because Terraform loads your kubeconfig file (if exists) when you run the plan and since the kubeconfig is created during the execution of the current plan, Terraform is not capable to find the cluster when you use resources like *kubernetes_deployment*, etc. This will, hopefully, change in the future.

Knowing that, basically what they want you to do is to have a Terraform plan to deploy the EKS cluster and another plan which will use the remote state of the first one to deploy the rest of your Kubernetes resources.

But, just to let you know, you can deploy the Kubernetes resources directly in the first plan by using the kubectl command directly. This is possible because when you create your EKS cluster you can, optionally, export the kubeconfig file to your local machine, then you can create a *null_resource* passing that kubeconfig as parameter and create your resources.
** If you are using that method, don't forget to wait for the endpoint to be accessible and returning a valid response (in my case, I created a bash script to validate) before start deploying any manifest.

## Understanding the code
For the VPC, and because this not the goal of this project, I am using the [AWS VPC Terraform module](https://github.com/terraform-aws-modules/terraform-aws-vpc).

For the EKS cluster I am using the AWS EKS module [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks). I'm writing out the *kubeconfig* and the *aws-auth configmap* file, if you don't want to do it, set to false the variables *write_kubeconfig* and *write_aws_auth_config*.

In the main.tf file I am updating your kubeconfig file executeing the necessary commands in the local machine. I'm doing this with a *null_resource* and the provisioner *local-exec*. 


## How to deploy
If you haven't ever used AWS EKS and Kubernetes before, you will need to install *kubectl* and *aws-iam-authenticator*. A good start point for you would be the Terraform learning resource [AWS EKS Introduction](https://learn.hashicorp.com/terraform/aws/eks-intro).

```bash
terraform apply
```

## Kubeconfig
You may have multiple K8s clusters and not want to pass your kubeconfig as a parameter for the *kubectl* command every time you want to use one of your clusters.

After creating the EKS cluster I update the kubeconfig automatically. But you can do it manually for other clusters if you like. Here's how you can do it:

1. Start listing your EKS clusters on AWS
```bash
aws eks list-clusters
# {
#    "clusters": [
#        "hello-eks"
#    ]
# } 
```

2. Add your EKS cluster to your kubeconfig file
```bash
aws eks update-kubeconfig --name hello-eks
#Added new context arn:aws:eks:eu-west-2:XXXXXXXXXXXX:cluster/hello-eks to /Users/XXXXXXX/.kube/config
```

3. Get all your contexts and use the context with which you want to work
```bash
kubectl config get-contexts
# CURRENT   NAME                                                          CLUSTER                                                       AUTHINFO                                                      NAMESPACE
# *         arn:aws:eks:eu-west-2:700161708181:cluster/hello-eks          arn:aws:eks:eu-west-2:700161708181:cluster/hello-eks          arn:aws:eks:eu-west-2:700161708181:cluster/hello-eks          
     
kubectl config use-context arn:aws:eks:eu-west-2:XXXXXXXXX:cluster/hello-eks
# Switched to context "arn:aws:eks:eu-west-2:XXXXXXXX:cluster/hello-eks".
```

You can now start *playing* with your cluster.
```bash
kubectl get nodes
# NAME                                        STATUS   ROLES    AGE   VERSION
# ip-10-1-10-93.eu-west-2.compute.internal    Ready    <none>   1h    v1.11.5
# ip-10-1-11-237.eu-west-2.compute.internal   Ready    <none>   1h    v1.11.5
# ip-10-1-12-79.eu-west-2.compute.internal    Ready    <none>   1h    v1.11.5

kubectl get all -n kube-system
# NAME                           READY   STATUS    RESTARTS   AGE
# pod/aws-node-b2v92             1/1     Running   0          1h
# pod/aws-node-fqcpk             1/1     Running   0          1h
# pod/aws-node-wt55j             1/1     Running   0          1h
# pod/coredns-854797898c-c7v97   1/1     Running   0          1h
# pod/coredns-854797898c-lc74n   1/1     Running   0          1h
# pod/kube-proxy-bz8z9           1/1     Running   0          1h
# pod/kube-proxy-gfllv           1/1     Running   0          1h
# pod/kube-proxy-kf85j           1/1     Running   0          1h

# NAME               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
# service/kube-dns   ClusterIP   172.20.0.10   <none>        53/UDP,53/TCP   1h

# NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
# daemonset.apps/aws-node     3         3         3       3            3           <none>          1h
# daemonset.apps/kube-proxy   3         3         3       3            3           <none>          1h

# NAME                      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/coredns   2         2         2            2           1h

# NAME                                 DESIRED   CURRENT   READY   AGE
# replicaset.apps/coredns-854797898c   2         2         2       1h
```