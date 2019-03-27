import os
import tempfile
import pytest
from hello import create_app


@pytest.fixture(scope="session")
def app():
    """An application for the tests."""
    app = create_app('hello_test.cfg')
    
    with app.app_context():
        from hello.views import hello_app
        app.register_blueprint(hello_app)
        yield app
   
    os.unlink(app.config['DB_PATH'])

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

