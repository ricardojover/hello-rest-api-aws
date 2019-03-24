## Undestanding the code

### remote_state.tf
We need to use the Terraform remote state to be able to access some variables of our EKS cluster. We will only be able to access those variables we have declared as outputs. You can take a look at the *outputs.tf* file in the *hello_eks_cluster* directory.

### locals.tf
Sometimes we want to have a variable that is the concatenation of several variables, common tags, dynamic variables, etc., and we don't want to repeat ourselves during the code. We can then use locals.

### database.tf
Creating a database using our own module.

### task_service_hello.tf
This is the most important file in this directory as we create our k8s resources in here.

I create here the deployment for our application, a load balancer and in another section in this file. Notice that I have to execute within a *null_resource* the command *kubectl annotate* to complete the configuration of the load balancer. This is because, at the time of writing, the Terraform's Kubernetes provider does not support internal annotations which I consider is one of the most useful things of Kubernetes.

Imagine that Kubernetes doesn't support, let's say, AWS Route 53, but you need to use it for your application because you want to have everything automated and configured in the same place. It happens that some nice people have already thought of that and they have created a resource for that and you can use it freely. This is the case of [ExternalDNS](https://github.com/kubernetes-incubator/external-dns).

Once deployed within your infrastructure, the way to use it is with annotations.
```yaml
kind: Service
apiVersion: v1
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "${local.fqdn}."
spec:
  selector:
    app: my-app
  ports:
    ...
  type: LoadBalancer
```

**local.fqdn** would be a variable created in the locals which could be ${var.environment}-${var.app_name}.${var.my_domain}

If you want to read more about Terraform K8s deployments and services:
* [kubernetes_deployment](https://www.terraform.io/docs/providers/kubernetes/r/deployment.html)
* [kubernetes_service](https://www.terraform.io/docs/providers/kubernetes/r/service.html)


## Good to know
Using Terraform we have a little less control over our k8s cluster. It's not a very big deal because we can handle the issues changing the Terraform code and in that way we'll have our TF states up to date. But it would be nice if we could have, for example, history of our deployments when we deploy our manifests using Terraform.

* Deploying 4 different versions with *Terraform*:
kubectl rollout history deployment.apps/hello-eks-hello-svc
deployment.apps/hello-eks-hello-svc 
REVISION  CHANGE-CAUSE
1         <none>

* Deploying 4 different versions with *kubectl apply*
kubectl rollout history deployment.apps/hello-eks-hello-svc
deployment.apps/hello-eks-hello-svc 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
4         <none>

Anyway, think that before production you have carefully tested all your applications in your dev and staging environments so that you won't have any issues on production.

But, in the future, Kubernetes will allow us to configure an auto-rollback as you can read [here](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#progress-deadline-seconds). At that point, if Terraform doesn't change that, Kubernetes will have no idea what to roll back. Hopefully this will change.
