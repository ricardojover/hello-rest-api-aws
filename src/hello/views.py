from flask import Flask, jsonify, request, make_response, abort, Blueprint
from http import HTTPStatus
from datetime import datetime
from hello.models import User, UserSchema, db_session
from hello.config import LocalConst
from hello import utils
import re


hello_app = Blueprint('hello', __name__)


def get_db_user(username):
    return User.query.filter(User.username == username).one_or_none()


@hello_app.route('/healthz', methods=['GET'])
def health_check():
    try:
        get_db_user('')
        return make_response(jsonify(alive=True), HTTPStatus.OK)
    except:
        abort(
            HTTPStatus.INTERNAL_SERVER_ERROR,
            "Unable to connect to the database",
        ) 


@hello_app.route('/hello', methods=['GET'])
def help():
    return LocalConst.usage


@hello_app.route('/hello/list-users', methods=['GET'])
def list():
    users = User.query.order_by(User.username).all()

    user_schema = UserSchema(many=True)
    data = user_schema.dump(users).data
    return jsonify(data)


@hello_app.route('/hello', methods=['POST'])
def add_user():
    payload = request.json
    if 'username' not in payload or 'dateOfBirth' not in payload:
        abort(HTTPStatus.BAD_REQUEST, "Malformed request")
    
    username = payload["username"]
    if not utils.validate_username(username):
        abort(
            HTTPStatus.BAD_REQUEST,
            "The username must be a string between 1 and 32 characters (no digits or any other special chars)",
        )
    date_of_birth = payload["dateOfBirth"]
    
    if not utils.validate_date_of_birth(date_of_birth):
        abort(
            HTTPStatus.BAD_REQUEST,
            "The valid format for the date of birth is YYYY-MM-DD and must be a date before the today date.",
        )

    db_user = get_db_user(username)

    if db_user is None:
        user_schema = UserSchema()
        new_user = User(username, date_of_birth)

        db_session.add(new_user)
        db_session.commit()

        data = user_schema.dump(new_user).data
        return make_response(jsonify(data), HTTPStatus.CREATED)
    else:
        abort(
            HTTPStatus.CONFLICT,
            "Username '{0}' already exists".format(username),
        )


@hello_app.route('/hello/<username>')
def user_info(username):
    db_user = get_db_user(username)

    if db_user is not None:
        days_to_bday = utils.get_days_to_bday(db_user.dateOfBirth)
        if days_to_bday == 0:
            message = "Hello, {0} Happy birthday!".format(username)
        else:
            message = "Hello, {0}! Your birthday is in {1} days(s)".format(username, days_to_bday)
        
        return (jsonify(message=message), HTTPStatus.OK)
    else:
        abort(
            HTTPStatus.NOT_FOUND,
            "Username '{0}' not found".format(username),
        )


@hello_app.route('/hello/<username>', methods=['PUT'])
def update(username):
    db_user = get_db_user(username)
    
    if db_user is not None:
        payload = request.json
        if 'dateOfBirth' not in payload:
            abort(HTTPStatus.BAD_REQUEST, "dateOfBirth is a mandatory field")
        else:
            date_of_birth = payload['dateOfBirth']
            if not utils.validate_date_of_birth(date_of_birth):
                abort(HTTPStatus.BAD_REQUEST,
                      "The valid format for the date of birth is YYYY-MM-DD and must be a date before the today date.",
                )
        
        user_schema = UserSchema()
        db_user.dateOfBirth = datetime.strptime(date_of_birth, "%Y-%m-%d").date() #date_of_birth
        db_session.merge(db_user)
        db_session.commit()

        data = user_schema.dump(db_user).data
        
        return make_response(jsonify(data), HTTPStatus.NO_CONTENT)
    

@hello_app.route('/hello/<username>', methods=['DELETE'])
def delete(username):
    db_user = get_db_user(username)

    if db_user is not None:
        db_session.delete(db_user)
        db_session.commit()
        return make_response(
            jsonify(message="Username '{0}' deleted".format(username)), HTTPStatus.OK
        )
    else:
        abort(
            HTTPStatus.NOT_FOUND,
            "Username '{0}' not found".format(username),
        )


@hello_app.route('/version', methods=['GET'])
def version():
    return make_response(
        jsonify(version="{0}".format(LocalConst.version)), HTTPStatus.OK
    )


