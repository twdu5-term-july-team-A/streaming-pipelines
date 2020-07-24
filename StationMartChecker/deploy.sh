#!/usr/bin/env bash

echo "====Copy dags to airflow server===="
scp ./StationMartChecker/dags/station-mart-checker.py airflow.${TRAINING_COHORT}.training:/home/ec2-user/airflow/dags
echo "====Dags copied to airflow server===="