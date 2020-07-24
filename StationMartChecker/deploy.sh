#!/usr/bin/env bash

echo "====Packaging===="
virtualenv station_mart_checker
mkdir station_mart_checker_contents && cd station_mart_checker_contents

pip install --install-option="--install-lib=$PWD" hdfs
pip install --install-option="--install-lib=$PWD" pytz
echo `pwd`
cp ../StationMartChecker/dags/* ./
zip -r station-mart-checker.zip ./*

echo "====Copy zip to airflow server===="
scp ./station-mart-checker.zip airflow.${TRAINING_COHORT}.training:/home/ec2-user/airflow/dags
echo "====Zip copied to airflow server===="