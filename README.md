# Hello REST-API

## Hello App
I have chosen Python with Flash and SQLAlchemy because it is very straightforward and quick to develop a basic application.
This application consists on a simple HTTP-based API that returns the days left to the user's birthday.

In this application I also allow the user to list all users in the database, add new users, change the date of birth and delete the users.
The username must contain only alphabetical characters (32 max).
The date of birth must be in the format "YYYY-MM-DD" and be a date before the today's date.

The code of the application is in the directory 'src'

## Hello Infrastructure
Terraform is still in development and immature for some technologies like Kubernetes, but for AWS this is, from my point of view, the best tool for building, changing, and versioning infrastructure safely and efficiently.

The goal is to deploy a simple REST API and be able to update the application with no downtime.

To get the goal I've created a basic ECS cluster using [Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html#launch-type-fargate) for our app and an application load balancer to be able to use the application from the Internet (in this case it'll be limited to "my_ips").

## Structure of the project

├── src
└── terraform
    ├── hello_ecs_fargate
    ├── hello_eks_cluster
    ├── hello_eks_services
    └── mysql

### src directory
This directory contains the files of our simple HTTP REST API.

### terraform
This directory contains all our terraform plans. 
I have created 4 different plans:
* mysql: I have created a module for the database because is common for the ECS and EKS clusters.
 

### Explaining the Fargate's code (terraform/hello_ecs_fargate)
#### vpc.tf
Since creating the network wasn't the objective I have directly used a terraform module to create the VPC, Internet gateway, NAT and subnets.

#### main.tf
Here is where we create the cluster and define the security group for our ECS tasks.
For security reasons the only resource that will be able to access the tasks is the load balancer.

#### provider.tf
I'm only using this because I may be in a different region when I'm deploying my plan. E.g. my AWS_DEFAULT_REGION could be in us-west-1 whilst I want to deploy to eu-west-2.

#### mysql.tf
I create here a MySQL database with [multi-az deployment](https://aws.amazon.com/rds/details/multi-az/). For security reasons as well I allow access only from the tasks on my ECS cluster.

#### tasks/hello.json.tmpl
This is the json template for the container definition.
We specify here things like what is the image to use, tag, memory, cpu, port mappings, environment variables, network mode, etc.
For more information about this look at [Creating a Task Definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html).

#### task_service_hello.tf
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

#### variables.tf
In this file you can find all variables that you will need for the deployment.
I have removed the value for the db_password so that you can write what you want. You can fill the variable, set it when you apply the Terraform plan, etc.

Note that in this case the instance port and the container port are the same. This is a limitation of Fargate because in Fargate the network mode must be *awsvpc* and in that case the host ports and container ports in port mappings must match.

#### output.tf
I use this file to display some important values I will need at the end of the deployment. In this case and because I haven't created any DNS entry I will need to know the DNS name of the load balancer to be able to use my application.

The outputs are more than useful when you are working with modules.

#### tests.tf & scripts/test-rest-api.sh.tmpl
At this point I'm assuming you are running all this on Mac, Linux or the Linux subsystem on Windows.
I'm using this file to create a bash script to test the deployed application.
I do not delete the file after run it so that you can add some more testing if you wish.


### System diagram
![System diagram](./aws_infra.png)


### Testing the app locally
You may want use vagrant or the Docker you can create with the Dockerfile in the main directory of this repository. But in case you've already got a mysql running on your localhost and the system dependencies, this are the steps you can run to test the application:

Requirements:

* Ensure you can create the database.
* Create environment variable called CONNECTION_STRING (= mysql://db_user:db_pass@host:port/db )
* Create another environment variable VERSION that matches the version of your app (in my case the docker tag)
* You must have python3 installed on your system
* You may need some system packages like openssl-dev, python3-dev and mysql-client to be able to build all the requirements with pip.


These bellow are some tests you can run on your machine:
```bash
python3 -m venv ./venv
source ./venv/bin/activate
pip install -r requirements.txt

mysql -uroot -p -e 'CREATE DATABASE IF NOT EXISTS hello;' 
mysql -uroot -p hello -e 'describe users;'
# ERROR 1146 (42S02) at line 1: Table 'hello.users' doesn't exist

python init_db.py
mysql -uroot -p hello -e 'describe users;'
#+-------------+-------------+------+-----+---------+----------------+
#| Field       | Type        | Null | Key | Default | Extra          |
#+-------------+-------------+------+-----+---------+----------------+
#| id          | int(11)     | NO   | PRI | NULL    | auto_increment |
#| username    | varchar(32) | YES  | UNI | NULL    |                |
#| dateOfBirth | date        | YES  |     | NULL    |                |
#+-------------+-------------+------+-----+---------+----------------+

pushd src
gunicorn -w 4 hello:app &
PID=`echo $!`
popd

curl http://localhost:8000/healthz
# {"alive":true}

curl http://localhost:8000/version
# {"version":"0.0.1"}

curl http://localhost:8000/hello
#Usage:
# 
#- GET    /hello/list-users
#- POST   /hello data={"username": "<username>", "dateOfBirth": "<dateOfBirth>"}
#- GET    /hello/<username>
#- PUT    /hello/<username> data={"dateOfBirth": "<dateOfBirth>"}
#- DELETE /hello/<username>

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"Ric","dateOfBirth":"1999-01-01"}' http://localhost:8000/hello
#{"dateOfBirth":"1999-01-01","id":1,"username":"Ric"}

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"Ric","dateOfBirth":"2004-04-20"}' http://localhost:8000/hello
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
#<title>409 Conflict</title>
#<h1>Conflict</h1>
#<p>Username 'Ric' already exists</p>

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"John","dateOfBirth":"2004-04-20"}' http://localhost:8000/hello
#{"dateOfBirth":"2004-04-20","id":2,"username":"John"}

curl http://localhost:8000/hello/list-users|jq '.'
#[
#  {
#    "dateOfBirth": "2004-04-20",
#    "id": 2,
#    "username": "John"
#  },
#  {
#    "dateOfBirth": "1999-01-01",
#    "id": 1,
#    "username": "Ric"
#  }
#]

curl http://localhost:8000/hello/Ric
#{"message":"Hello, Ric! Your birthday is in 288 days(s)"}

curl -v -XPUT -H 'Content-Type: application/json' -d '{"dateOfBirth":"2019-03-19"}' http://localhost:8000/hello/Ric
# * Connected to localhost (127.0.0.1) port 8000 (#0)
# > PUT /hello/Ric HTTP/1.1
# > Host: localhost:8000
# > User-Agent: curl/7.54.0
# > Accept: */*
# > Content-Type: application/json
# > Content-Length: 28
# > 
# * upload completely sent off: 28 out of 28 bytes
# < HTTP/1.1 204 NO CONTENT
# < Server: gunicorn/19.9.0
# < Date: Tue, 19 Mar 2019 16:35:58 GMT
# < Connection: close
# < Content-Type: application/json
# < Content-Length: 53
# < 
# * Closing connection 0

curl http://localhost:8000/hello/Ric
# {"message":"Hello, Ric Happy birthday!"}

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"Potatoe","dateOfBirth":"2044-04-20"}' http://localhost:8000/hello
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
# <title>400 Bad Request</title>
# <h1>Bad Request</h1>
# <p>The valid format for the date of birth is YYYY-MM-DD and must be a date before the today date.</p>

curl -XPUT -H 'Content-Type: application/json' -d '{"dateOfBirth":"2055-03-19"}' http://localhost:8000/hello/Ric
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
# <title>400 Bad Request</title>
# <h1>Bad Request</h1>
# <p>The valid format for the date of birth is YYYY-MM-DD and must be a date before the today date.</p>

curl -XDELETE -H 'Content-Type: application/json' http://localhost:8000/hello/John
#{"message":"Username 'John' deleted"}

curl http://localhost:8000/hello/list-users|jq '.'
#[
#  {
#    "dateOfBirth": "2019-03-19",
#    "id": 1,
#    "username": "Ric"
#  }
#]

kill $PID

```

### Testing the app on AWS
The Terraform plan will create a file called 'test-rest-api.sh' after everything is successfully deployed.
That file will be run the first time you deploy the Terraform plan and every time you change the template and re-run the Terraform plan.
But, since I do not delete the file after run it, you can alter the content to add you own tests and run it as many times as you want.

