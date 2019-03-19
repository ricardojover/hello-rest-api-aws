#!/bin/sh

cd /hello
python3 init_db.py
gunicorn -w 4 -b 0.0.0.0 hello:app