#!/bin/sh

set -e

SERVICE_URI=$1

for i in 1 2 3 4 5 6 7 8 9 10
do
  BANK_IS_OPEN=1
  curl $SERVICE_URI || BANK_IS_OPEN=0
  if [ $BANK_IS_OPEN -eq 1 ]; then
    break
  fi
  echo "Service is not running. Trying again..."
  sleep 10
done

