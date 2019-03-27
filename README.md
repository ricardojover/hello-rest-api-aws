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
```
.
├── src
└── terraform
    ├── hello_ecs_fargate
    ├── hello_eks_cluster
    ├── hello_eks_services
    └── mysql
```

### Root directory
The most important files in this directory are the Dockefile, the entrypoint for the docker and the requirements file.

To build the docker I have chosen Alpine because is pretty small and I don't want to have installed more than I need to run my app.
The requirements file contains all the necessary libraries and applications to run the app, like Flask and gunicorn.
The entrypoint file initialises the database and starts the application using gunicorn with 4 workers and listening on all ipv4 interfaces.

### src
This directory contains the files of our simple HTTP REST API.

### terraform
This directory contains all our terraform plans. 
I have created 4 different plans:
* **mysql**. I have created a module for the database because is common for the ECS and EKS clusters.
* **hello_ecs_fagate**. With the plan in this directory you will be able to build an ECS cluster using Fargate to run the *hello* service.
* **hello_eks_cluster**. Here we will create the EKS cluster.
* **hello_eks_services**. We will deploy with this code the necessary infrastructure to run our application using Kubernetes.

The reason why we have to create first the cluster and then the rest of the services using that cluster in Kubernetes is basically due to a limitation in Terraform. You can read more about this in the *hello_eks_cluster* directory.

To undestand a little more about each one of the Terraform plans, please, you only need to access the directory.


## System diagram
![System diagram](./aws_infra.png)


## Testing the app locally
Build and run the docker (you will have to be in the root folder of this project).

When you run the docker with the environment pytest, the docker will automatically run the set of tests defined in the tests directory (src/tests)
```bash
docker build -t hello_rest_api .
docker run --rm --name hello -e ENV=pytest hello_rest_api

# ============================= test session starts ==============================
# ...
# tests/test_views.py::test_healthz PASSED                                 [  8%]
# ...
# tests/test_views.py::test_delete_user[John] PASSED                       [100%]

# ...
# ==================== 12 passed, 1 warnings in 0.22 seconds =====================
# Name                Stmts   Miss Branch BrPart  Cover   Missing
# ---------------------------------------------------------------
# hello/__init__.py      30      5      6      2    75%   18, 33-36, 46, 17->18, 31->33
# hello/config.py         4      0      0      0   100%
# hello/models.py        22      0      0      0   100%
# hello/utils.py         18      1      4      1    91%   25, 20->25
# hello/views.py         75      9     20      6    84%   22-23, 31, 47, 51, 94, 107, 136, 144, 46->47, 50->51, 85->94, 104->exit, 106->107, 129->136
# ---------------------------------------------------------------
# TOTAL                 149     15     30      9    85%
``` 


If you rather test it more manually using curl, after building the docker as I explained above, run the docker using the environment "manual_test" and expose the port 8000.

```bash
docker run -d --rm --name hello -e ENV=manual_test -p8000:8000 hello_rest_api

curl http://localhost:8000/healthz
# {"alive":true}

curl http://localhost:8000/hello
# Usage:
# 
# - GET    /hello/list-users
# - POST   /hello data={"username": "<username>", "dateOfBirth": "<dateOfBirth>"}
# - GET    /hello/<username>
# - PUT    /hello/<username> data={"dateOfBirth": "<dateOfBirth>"}
# - DELETE /hello/<username>

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"Ric","dateOfBirth":"1999-01-01"}' http://localhost:8000/hello
#{"dateOfBirth":"1999-01-01","id":1,"username":"Ric"}

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"Ric","dateOfBirth":"2004-04-20"}' http://localhost:8000/hello
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
# <title>409 Conflict</title>
# <h1>Conflict</h1>
# <p>Username 'Ric' already exists</p>

curl -XPOST -H 'Content-Type: application/json' -d '{"username":"John","dateOfBirth":"2004-04-20"}' http://localhost:8000/hello
# {"dateOfBirth":"2004-04-20","id":2,"username":"John"}

curl http://localhost:8000/hello/list-users|jq '.'
# [
#   {
#     "dateOfBirth": "2004-04-20",
#     "id": 2,
#     "username": "John"
#   },
#   {
#     "dateOfBirth": "1999-01-01",
#     "id": 1,
#     "username": "Ric"
#   }
# ]

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
# {"message":"Username 'John' deleted"}

curl http://localhost:8000/hello/list-users|jq '.'
# [
#   {
#     "dateOfBirth": "2019-03-19",
#     "id": 1,
#     "username": "Ric"
#   }
# ]

docker kill hello
```

## Testing the app on AWS
The Terraform plan will create a file called 'test-rest-api.sh' after everything is successfully deployed.
That file will be run the first time you deploy the Terraform plan and every time you change the template and re-run the Terraform plan.
But, since I do not delete the file after run it, you can alter the content to add you own tests and run it as many times as you want.

