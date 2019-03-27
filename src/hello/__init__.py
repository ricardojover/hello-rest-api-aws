from flask import Flask
from sqlalchemy import create_engine
from hello import models
import os


def initialise_database(engine):
    models.Base.metadata.create_all(bind=engine)


def create_app(config_file):
    app = Flask(__name__, instance_relative_config=True)

    app.config.from_pyfile(config_file)
    
    with app.app_context():
        if not 'SQLALCHEMY_DATABASE_URI' in app.config:
            raise Exception("App missconfigured")
            
        connection_string = app.config['SQLALCHEMY_DATABASE_URI']
        engine = create_engine(connection_string, convert_unicode=True)
        models.db_session.configure(bind=engine)
        models.Base.metadata.bind = engine
        
        initialise_database(engine)

    return app


env = os.environ.get('ENV')
if env is None or env == 'test':
    config_file = "hello_test.cfg"
elif env == 'prod':
    config_file = "hello.cfg"
else:
    raise Exception("The environment '{0}' is not valid.".format(env))

app = create_app(config_file)

from hello.views import hello_app
app.register_blueprint(hello_app)


@app.teardown_appcontext
def shutdown_session(exception=None):
    models.db_session.remove()

