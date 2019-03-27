import pytest
import json
import re
from datetime import datetime
from hello.views import get_db_user
from hello.utils import get_days_to_bday, validate_date_of_birth
from hello import create_app


ERROR_USER_EXISTS = b'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">\n<title>409 Conflict</title>\n<h1>Conflict</h1>\n<p>Username \'Ric\' already exists</p>\n'
ERROR_INVALID_DATE = b'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">\n<title>400 Bad Request</title>\n<h1>Bad Request</h1>\n<p>The valid format for the date of birth is YYYY-MM-DD and must be a date before the today date.</p>\n'


def headers():
    headers = {
        'Content-Type': 'application/json'
    }
    return headers


def test_healthz(client):
    response = client.get('healthz')
    assert response.data == b'{\n  "alive": true\n}\n'


@pytest.mark.parametrize(('username', 'dateOfBirth', 'id'), (
    ('Ric', '1999-01-01', 1),
    ('John', '2004-04-20', 2),
    ('Ric', '2000-01-01', 3),
    ('Unborn', '2199-01-01', 3),
))
def test_add_users(client, app, username, dateOfBirth, id):
    user_already_exists = get_db_user(username) is not None

    user = {'username': username, 'dateOfBirth': dateOfBirth}
    response = client.post('/hello', data=json.dumps(user), headers=headers())

    if user_already_exists:
        assert response.data == ERROR_USER_EXISTS
    else:
        today = datetime.today().date()
        date_of_birth = datetime.strptime(dateOfBirth, "%Y-%m-%d").date()
        if (date_of_birth <= today):
            assert response.json == {'dateOfBirth': dateOfBirth, 'id': id, 'username': username}

            with app.app_context():
                db_user = get_db_user(username)

                if db_user is not None:
                    assert db_user.username == username
                    assert db_user.dateOfBirth == date_of_birth
                    assert db_user.id == id 
        else:
            assert response.data == ERROR_INVALID_DATE


def test_list_users(client):
    response = client.get('/hello/list-users')
    assert response.json == [{'dateOfBirth': '2004-04-20', 'id': 2, 'username': 'John'},
                            {'dateOfBirth': '1999-01-01', 'id': 1, 'username': 'Ric'}]


def _user_birthday(client, app, username):
    response = client.get('/hello/' + username)

    db_user = get_db_user(username)
    days_to_bday = get_days_to_bday(db_user.dateOfBirth)

    if days_to_bday > 0:
      assert response.json == {'message': 'Hello, {username}! Your birthday is in {days_to_bday} days(s)'.format(username=username, days_to_bday=days_to_bday)}
    else: 
      assert response.json == {'message': 'Hello, {username} Happy birthday!'.format(username=username)}


@pytest.mark.parametrize('username', (
    'Ric',
    'John',
))
def test_user_birthday(client, app, username):
    _user_birthday(client, app, username)


def _update_date_of_birth(client, app, username, dateOfBirth):
    dob_json = {'dateOfBirth': dateOfBirth}
    response = client.put('/hello/{0}'.format(username), data=json.dumps(dob_json), headers=headers())

    today = datetime.today().date()
    date_of_birth = datetime.strptime(dateOfBirth, "%Y-%m-%d").date()
    
    if today >= date_of_birth:
        assert validate_date_of_birth(dateOfBirth)
        assert response.status_code == 204
    else:
        assert not validate_date_of_birth(dateOfBirth)
        assert response.data == ERROR_INVALID_DATE
    

@pytest.mark.parametrize('username', (
    'Ric',
))
def test_update_ric_date_of_birth(client, app, username):
    today = datetime.today().strftime("%Y-%m-%d")
    _update_date_of_birth(client, app, username, today)
    

@pytest.mark.parametrize('username', (
    'Ric',
))
def test_wish_ric_happy_birthday(client, app, username):
    _user_birthday(client, app, username)


@pytest.mark.parametrize('username', (
    'Ric',
))
def test_update_date_of_birth_to_future(client, app, username):
    _update_date_of_birth(client, app, username, '2199-01-01')


@pytest.mark.parametrize('username', (
    'John',
))
def test_delete_user(client, app, username):
    response = client.delete('/hello/{0}'.format(username))

    assert response.json == {'message': "Username '{0}' deleted".format(username)}

