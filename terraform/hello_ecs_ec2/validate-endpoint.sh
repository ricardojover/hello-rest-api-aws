#!/bin/bash
ENDPOINT=$1
TIMEOUT=300
START_TIME=`date +%s`

if [ -z "$ENDPOINT" ]; then
  echo "Missing endpoint"
  exit 1
fi

while true; do
  HEALTH=$(curl -s $ENDPOINT/healthz)
  if [ "$HEALTH" = "{\"alive\":true}" ]; then 
    echo "Reached '$ENDPOINT' successfully"
    exit 0
  fi

  CURRENT_TIME=`date +%s`
  ELAPSED_TIME_IN_SECONDS=$(( $CURRENT_TIME - $START_TIME ))
  if [ $ELAPSED_TIME_IN_SECONDS -gt $TIMEOUT ]; then
    exit 1
  fi
  printf .
  sleep 10
  
done
