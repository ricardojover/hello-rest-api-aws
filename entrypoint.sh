#!/bin/bash

cd /hello

run_app(){
  gunicorn -w 4 -b 0.0.0.0 hello:app
}

testing(){
  coverage run -m pytest
  coverage report -m
  exit 0
}

VALID_ENVS=("prod" "production" "qa" "manual_test" "pytest" "auto_test")

case "$ENV" in
  "prod" | "production")
    export ENV="prod"
    run_app
    ;;
  "qa" | "manual_test")
    export ENV="test"
    run_app
    ;;
  "pytest" | "auto_test")
    export ENV="test"
    testing
    ;;
  *)
    echo "The environment '$ENV' is not valid.'"
    echo "Valid environments are:"
    for e in ${VALID_ENVS[@]}; do
      printf "\t${e}\n"
    done
    exit 1
    ;;
esac

