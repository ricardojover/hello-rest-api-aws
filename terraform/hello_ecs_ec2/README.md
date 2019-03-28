## Overview
There are a few differences between this and the other two Terraform plans.

First, I create my own network with only public subnets because I don't want to deploy a bastion to access my servers and I can configure my security groups to allow only my IPs over the port 22 for management access... This is only a proof of concept anyway.

Second, whilst the two other plans are "serverless" (AWS manages the servers for Fargate and for EKS at least the masters) with the ECS EC2 we manage our own servers. This is useful if you want to have more control of your servers, etc.

With this option you will need to deploy the ECS agent so that AWS ECS can deploy the tasks and services, auto-scale them when necessary, etc. This plan will do this by adding a systemd unit that I have configured in the user data.

## Understanding the code
I am not going to repeat myself, so I'm only going to talk about the Terraform files you can't see in the other plans.

### iam.tf
In this file I create the IAM role and its policy, necessary for the ECS hosts to work properly. You don't need to do that when using Fargate as AWS do it for you.

### ignition.tf
This file contains all the user data we are going to deploy in every single instance. You can write the user data in YAML, load the template and render it or, since Terraform supports ignition, it is far way easier and nicer to use this way.

### network.tf
I create here the VPC, Internet gateway, subnets and route tables. Briefly, all the necessary for our machines to have connectivity among them and with the internet.

### main.tf
The first thing I do in this file is to create the ecs cluster. I will reference it later by its name in the rest of our resources.

After that I search for the AMI... Sadly there are many many people that hardcode the AMI ID in their launch configurations! That makes sense when you are using your own private AMI, but not when you are using a public one. If you are using a hardcoded AMI ID, you have to think that it'll be different in every region, which means that if you are thinking of deploying your instances in 10 regions you will have 10 different AMI IDs and when you have to update your OS because an important security patch, let's say for instance [CVE-2019-5736](https://www.openwall.com/lists/oss-security/2019/02/11/2), you will have to go region per region looking at the latest AMI ID of your OS. It's a bit crazy, isn't it ?
Well, with the method I use you will only need to write the name of the last released version (or the one you want to use) of your favourite OS.

#### Launch configuration
This is, probably, the most important section of our cluster as we define our instance in here. Every time we scale up our cluster it'll get all this data to create a new instance, so don't mess it up !

```hcl
resource "aws_launch_configuration" "hello_cluster" {
  image_id                    = "${data.aws_ami.coreos_ami.id}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.ecs_host.id}"]

  user_data                   = "${data.ignition_config.userdata.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.hello_ecs.id}"
  name_prefix                 = "${var.cluster_name}_lc"

  root_block_device {
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

There are tons of options for the launch configuration as you can see in [aws_launch_configuration](https://www.terraform.io/docs/providers/aws/r/launch_configuration.html). But I'm only using what I need for my cluster.

Arguments:
* *key_name*. This key must exist in your AWS region and you must have it in your computer if you want to be able to access your ECS hosts.
* *instance_type*. If you are only testing you may want the smallest possibe, but think that you will be running at least 3 dockers, so don't be too cheap :) . On the other hand, if you have bought reserved instance types in your region, use them instead of creating a t2.small or whatever as it'll be cheaper.
* *security_groups*. Who will be able to access the ECS hosts ?
* *[user_data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)*. The user data is used to deploy your custom configurations during the first launch. For instance, to configure your systemd units, to download and configure software, etc.
* *iam_instance_profile*. We specify here the role for our instance. In this case I have created this role in the *iam.tf* file.
* *root_block_device*. This is optional, but why should AWS decide how much space I need in my hosts ? I'm the one who knows the best...
* *lifecycle*. Well, imagine the disaster if we delete the launch configuration before creating a new one and the new one fails !!! That's why I use the argument *create_before_destroy* and set it true.


#### Autoscaling group
In this section I specify the minimum number of instances running, the desired capacity and the maximum. Every time we scale up it'll be using the launch configuration described above to deploy the new instance.
This is the nice thing about the immutable instances. We can scale up, down, destroy all, create again and it'll always be the same.
Same as we have got health check in our load balancers to check our applications we can define here different health checks, in this case I use the type EC2 because I want to be sure that my instance is working properly and because I already define an health check in the application load balancer.

#### Tip
If you are thinking of deploying X tasks you should always have at least one more instance. This is because if you want to upgrade your application and there are two instances already running in two servers it will take ages (actually 10 minutes), for the current app to die before the new version is deployed. That means that if you've got 3 instances and 3 tasks, you will have to wait for about 30 minutes to have your app updated everywhere.

In this case I have double instances than tasks to make the upgrade the quickest possible. In this way the two tasks will be deployed and the two old killed within seconds.

