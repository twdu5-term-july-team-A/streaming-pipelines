
from datetime import datetime, timedelta
from time import time

import pytz
from airflow import DAG
from airflow.contrib.hooks import aws_sns_hook
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from hdfs import InsecureClient

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2018, 8, 1),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

file_alive_threshold = int(Variable.get('file_alive_threshold'))
utc = pytz.timezone("UTC")
hdfs_server_endpoint = Variable.get('hdfs_server_endpoint')
csv_file_path = Variable.get('csv_file_path')
topicArn = Variable.get('sns_csv_publisher_topic_arn')
env = Variable.get('env')

def send_sns_notification():

    message = 'CSV UPDATE ERROR - %s \n\nIt seems like the %s file was last updated more than %d seconds ago' % (env, csv_file_path, file_alive_threshold)
    sns_client = aws_sns_hook.AwsSnsHook(aws_conn_id='aws_sns_connection')
    response = sns_client.publish_to_target(topicArn, message)
    print(response)


def check_for_fresh_file(ds, **kwargs):
    print('Checking whether the file %s exists in %s-hdfs server' % (csv_file_path, env))

    client = InsecureClient(hdfs_server_endpoint, user='root')
    csv_meta_data = client.status(csv_file_path)
    access_time = csv_meta_data['accessTime']
    current_time = int(time() * 1000)
    last_modified_time_delta_in_seconds = (current_time - access_time) / 1000

    if last_modified_time_delta_in_seconds > file_alive_threshold:
        print("The file %s is not updated inbetween the last %s seconds" % (csv_file_path, file_alive_threshold))
        send_sns_notification()
    else:
        print("The file %s is up to date." % csv_file_path)


file_checker_dag = DAG('station_mart_checker',
                       description='Python DAG',
                       schedule_interval='*/10 * * * *',
                       start_date=datetime(2018, 11, 1),
                       catchup=False,
                       is_paused_upon_creation=False)

t1 = PythonOperator(
    task_id='check_for_fresh_csv_file',
    provide_context=True,
    python_callable=check_for_fresh_file,
    dag=file_checker_dag,
)
