from setuptools import setup, find_packages

requirements = [
    'Click==7.0',
    'Flask==1.0.2',
    'Flask-MySQLdb==0.2.0',
    'itsdangerous==1.1.0',
    'Jinja2==2.10',
    'MarkupSafe==1.1.1',
    'marshmallow==2.19.0',
    'marshmallow-sqlalchemy==0.16.1',
    'mysqlclient==1.4.2.post1',
    'psycopg2==2.7.7',
    'SQLAlchemy==1.3.1',
    'Werkzeug==0.14.1',
    'gunicorn==19.9.0'
]

setup(
    name='hello',
    version='0.0.1',
    license='MIT',
    author='Ricardo Jover',
    author_email='',
    description='Simple HTTP REST API',
    packages=find_packages(),
    install_requires=requirements,
    entry_points={
        'console_scripts': [
            'run_broker = hello.worker:run_worker',
        ],
    },
    scripts=[
        'hello/worker.py',
    ],
)

