import os


class LocalConst:
    connection_string = os.environ.get('CONNECTION_STRING')
    version = os.environ.get('VERSION')
    
    usage = """
Usage:
 
- GET    /hello/list-users
- POST   /hello data={"username": "<username>", "dateOfBirth": "<dateOfBirth>"}
- GET    /hello/<username>
- PUT    /hello/<username> data={"dateOfBirth": "<dateOfBirth>"}
- DELETE /hello/<username> 

"""

