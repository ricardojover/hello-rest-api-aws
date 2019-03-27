import os

class LocalConst:
    version = "0.0.1"
    usage = """
Usage:
 
- GET    /hello/list-users
- POST   /hello data={"username": "<username>", "dateOfBirth": "<dateOfBirth>"}
- GET    /hello/<username>
- PUT    /hello/<username> data={"dateOfBirth": "<dateOfBirth>"}
- DELETE /hello/<username> 

"""
