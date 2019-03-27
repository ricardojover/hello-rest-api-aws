# coding: utf-8
from sqlalchemy import Column, Date, String, cast
from sqlalchemy.dialects.mysql import INTEGER
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from marshmallow_sqlalchemy import ModelSchema
from datetime import datetime


db_session = scoped_session(sessionmaker(autocommit=False, autoflush=False))

Base = declarative_base()
metadata = Base.metadata
Base.query = db_session.query_property()


class User(Base):
    __tablename__ = 'users'

    id = Column(INTEGER(11), primary_key=True)
    username = Column(String(32), unique=True)
    dateOfBirth = Column(Date)

    def __init__(self, username=None, date_of_birth=None):
        self.username = username
        self.dateOfBirth = datetime.strptime(date_of_birth, "%Y-%m-%d").date()

#    def __repr__(self):
#        return '<User %r>' % (self.username)

class UserSchema(ModelSchema):
    class Meta:
        model = User
        sqla_session = db_session

