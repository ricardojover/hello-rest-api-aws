### Explaining the Fargate's code (terraform/hello_ecs_fargate)

### vpc.tf
Since creating the network wasn't the objective I have directly used a terraform module to create the VPC, Internet gateway, NAT and subnets.

### main.tf
Here is where we create the cluster and define the security group for our ECS tasks.
For security reasons the only resource that will be able to access the tasks is the load balancer.

### database.tf
I create here a MySQL database with [multi-az deployment](https://aws.amazon.com/rds/details/multi-az/) using the *mysql* module that you can find in the terraform directory. Notice only the ECS tasks will be able to access the database (*allowed_security_groups*).

### provider.tf
I'm only using this because I may be in a different region when I'm deploying my plan. E.g. my AWS_DEFAULT_REGION could be in us-west-1 whilst I want to deploy to eu-west-2.

### tasks/hello.json.tmpl
This is the json template for the container definition.
We specify here things like what is the image to use, tag, memory, cpu, port mappings, environment variables, network mode, etc.
For more information about this look at [Creating a Task Definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html).

### task_service_hello.tf
This is the most important file in this project as this is where we define our task and the load balancer for it.

The first thing we do is to load the template and replace the variables with actual values.

Then we create the task definition. Since we are using **Fargate** there are a few mandatory arguments that otherwise wouldn't, which are the networkMode (must be *awsvpc*), requires_compatibilities, cpu and memory.

In the aws_ecs_service you'll see that I'm using the network_configuration. That argument is usually optional, but it's mandatory when using *awsvpc*.

We are also specifying the load balancer that will connect our application with the Internet. If you want to use HTTPS uncomment the commented lines and comment out or delete the lines port and protocol. You will also need to uncomment the variable ssl_cert_arn in the variables.tf file and set your own value.

In the next section we create the application load balancer and there we configure the health check.
The **health check** is extremely important because this will tell our cluster if the new deployed instance is ready to go or is "sick" and can't go and needs a roll back.
For more information about the health check on ECS click [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_healthcheck)

In the last section in this file we create the security group that will give us access from "my_ips" to the ALB which will make it possible to use the application.

Feel free to replace my_ips to 0.0.0.0/0 to make it accessible to all the Internet (not recommended though for this application).

### variables.tf
In this file you can find all variables that you will need for the deployment.
I have removed the value for the db_password so that you can write what you want. You can fill the variable, set it when you apply the Terraform plan, etc.

Note that in this case the instance port and the container port are the same. This is a limitation of Fargate because in Fargate the network mode must be *awsvpc* and in that case the host ports and container ports in port mappings must match.

### output.tf
I use this file to display some important values I will need at the end of the deployment. In this case and because I haven't created any DNS entry I will need to know the DNS name of the load balancer to be able to use my application.

The outputs are more than useful when you are working with modules.

### tests.tf & scripts/test-rest-api.sh.tmpl
At this point I'm assuming you are running all this on Mac, Linux or the Linux subsystem on Windows.
I'm using this file to create a bash script to test the deployed application.
I do not delete the file after run it so that you can add some more testing if you wish.

