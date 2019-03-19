# coding: utf-8
from database import Base, db_session
from sqlalchemy import Column, Date, String
from sqlalchemy.dialects.mysql import INTEGER
from sqlalchemy.ext.declarative import declarative_base
from marshmallow_sqlalchemy import ModelSchema


metadata = Base.metadata

class User(Base):
    __tablename__ = 'users'

    id = Column(INTEGER(11), primary_key=True)
    username = Column(String(32), unique=True)
    dateOfBirth = Column(Date)

    def __init__(self, username=None, date_of_birth=None):
        self.username = username
        self.dateOfBirth = date_of_birth


class UserSchema(ModelSchema):
    class Meta:
        model = User
        sqla_session = db_session

