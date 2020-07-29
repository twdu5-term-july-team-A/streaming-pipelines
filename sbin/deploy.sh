#!/usr/bin/env bash

set -xe

usage() {
    echo "Deployment script "
    echo "./deploy.sh BASTION_PUBLIC_IP TRAINING_COHORT"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

BASTION_PUBLIC_IP=$1
TRAINING_COHORT=$2
ENV=$3
HOST_SUFFIX=""
if [ ${ENV} != "prod" ]; then
   HOST_SUFFIX="-${ENV}"
fi

EMR_MASTER_HOST=emr-master${HOST_SUFFIX}.${TRAINING_COHORT}.training
KAFKA_HOST=kafka${HOST_SUFFIX}.${TRAINING_COHORT}.training

echo "====Updating SSH Config===="

echo "
	User ec2-user
	IdentitiesOnly yes
	ForwardAgent yes
	DynamicForward 6789
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host ${EMR_MASTER_HOST}
    User hadoop

Host *.${TRAINING_COHORT}.training !bastion.${TRAINING_COHORT}.training
	ForwardAgent yes
	ProxyCommand ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${BASTION_PUBLIC_IP} -W %h:%p 2>/dev/null
	User ec2-user
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host bastion.${TRAINING_COHORT}.training
    User ec2-user
    HostName ${BASTION_PUBLIC_IP}
    DynamicForward 6789
" >> ~/.ssh/config

echo "====SSH Config Updated===="

echo "====Insert app config in zookeeper===="
scp ./zookeeper/seed.sh ${KAFKA_HOST}:/tmp/zookeeper-seed.sh
ssh ${KAFKA_HOST} <<EOF
set -e
export hdfs_server="${EMR_MASTER_HOST}:8020"
export kafka_server="${KAFKA_HOST}:9092"
export zk_command="zookeeper-shell localhost:2181"
sh /tmp/zookeeper-seed.sh
EOF

echo "====Inserted app config in zookeeper===="

echo "====Copy jar to ingester server===="
scp CitibikeApiProducer/build/libs/tw-citibike-apis-producer0.1.0.jar ingester${HOST_SUFFIX}.${TRAINING_COHORT}.training:/tmp/
echo "====Jar copied to ingester server===="

echo "====Copy kill script ingester server===="
scp sbin/kill_process.sh ingester${HOST_SUFFIX}.${TRAINING_COHORT}.training:/tmp/kill_process.sh
echo "====Kill script copied to ingester server===="


ssh ingester${HOST_SUFFIX}.${TRAINING_COHORT}.training <<EOF
set -e
sh /tmp/kill_process.sh

echo "====Runing Producers Killed===="

station_information="station-information"
station_status="station-status"
station_san_francisco="station-san-francisco"
station_france="station-france"

echo "====Deploy Producers===="
nohup java -jar /tmp/tw-citibike-apis-producer0.1.0.jar --spring.profiles.active=\${station_information} --kafka.brokers=${KAFKA_HOST}:9092 1>/tmp/\${station_information}.log 2>/tmp/\${station_information}.error.log &
nohup java -jar /tmp/tw-citibike-apis-producer0.1.0.jar --spring.profiles.active=\${station_san_francisco} --producer.topic=station_data_sf --kafka.brokers=${KAFKA_HOST}:9092 1>/tmp/\${station_san_francisco}.log 2>/tmp/\${station_san_francisco}.error.log &
nohup java -jar /tmp/tw-citibike-apis-producer0.1.0.jar --spring.profiles.active=\${station_status} --kafka.brokers=${KAFKA_HOST}:9092 1>/tmp/\${station_status}.log 2>/tmp/\${station_status}.error.log &
nohup java -jar /tmp/tw-citibike-apis-producer0.1.0.jar --spring.profiles.active=\${station_marseille} --kafka.brokers=${KAFKA_HOST}:9092 1>/tmp/\${station_marseille}.log 2>/tmp/\${station_marseille}.error.log &

echo "====Producers Deployed===="
EOF


echo "====Configure HDFS paths===="
scp ./hdfs/seed.sh ${EMR_MASTER_HOST}:/tmp/hdfs-seed.sh

ssh ${EMR_MASTER_HOST} <<EOF
set -e
export hdfs_server="${EMR_MASTER_HOST}:8020"
export hadoop_path="hadoop"
sh /tmp/hdfs-seed.sh
EOF

echo "====HDFS paths configured==="


echo "====Copy Raw Data Saver Jar to EMR===="
scp RawDataSaver/target/scala-2.11/tw-raw-data-saver_2.11-0.0.1.jar ${EMR_MASTER_HOST}:/tmp/
echo "====Raw Data Saver Jar Copied to EMR===="

scp sbin/go.sh ${EMR_MASTER_HOST}:/tmp/go.sh

ssh ${EMR_MASTER_HOST} <<EOF
set -e

source /tmp/go.sh

echo "====Kill Old Raw Data Saver===="

kill_application "StationStatusSaverApp"
kill_application "StationInformationSaverApp"
kill_application "StationDataSFSaverApp"

echo "====Old Raw Data Saver Killed===="

echo "====Deploy Raw Data Saver===="

nohup spark-submit --master yarn --deploy-mode cluster --class com.tw.apps.StationLocationApp --name StationStatusSaverApp --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0 --driver-memory 500M --conf spark.executor.memory=2g --conf spark.cores.max=1 /tmp/tw-raw-data-saver_2.11-0.0.1.jar ${KAFKA_HOST}:2181 "/tw/stationStatus" 1>/tmp/raw-station-status-data-saver.log 2>/tmp/raw-station-status-data-saver.error.log &

nohup spark-submit --master yarn --deploy-mode cluster --class com.tw.apps.StationLocationApp --name StationInformationSaverApp --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0 --driver-memory 500M --conf spark.executor.memory=2g --conf spark.cores.max=1 /tmp/tw-raw-data-saver_2.11-0.0.1.jar ${KAFKA_HOST}:2181 "/tw/stationInformation" 1>/tmp/raw-station-information-data-saver.log 2>/tmp/raw-station-information-data-saver.error.log &

nohup spark-submit --master yarn --deploy-mode cluster --class com.tw.apps.StationLocationApp --name StationDataSFSaverApp --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0 --driver-memory 500M --conf spark.executor.memory=2g --conf spark.cores.max=1 /tmp/tw-raw-data-saver_2.11-0.0.1.jar ${KAFKA_HOST}:2181 "/tw/stationDataSF" 1>/tmp/raw-station-data-sf-saver.log 2>/tmp/raw-station-data-sf-saver.error.log &

echo "====Raw Data Saver Deployed===="
EOF


echo "====Copy Station Consumers Jar to EMR===="
scp StationConsumer/target/scala-2.11/tw-station-consumer_2.11-0.0.1.jar ${EMR_MASTER_HOST}:/tmp/

scp StationTransformerNYC/target/scala-2.11/tw-station-transformer-nyc_2.11-0.0.1.jar ${EMR_MASTER_HOST}:/tmp/
echo "====Station Consumers Jar Copied to EMR===="

scp sbin/go.sh ${EMR_MASTER_HOST}:/tmp/go.sh

ssh ${EMR_MASTER_HOST} <<EOF
set -e

source /tmp/go.sh


echo "====Kill Old Station Consumers===="

kill_application "StationApp"
kill_application "StationTransformerNYC"

echo "====Old Station Consumers Killed===="

echo "====Deploy Station Consumers===="

nohup spark-submit --master yarn --deploy-mode cluster --class com.tw.apps.StationApp --name StationApp --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0  --driver-memory 500M --conf spark.executor.memory=2g --conf spark.cores.max=1 /tmp/tw-station-consumer_2.11-0.0.1.jar ${KAFKA_HOST}:2181 1>/tmp/station-consumer.log 2>/tmp/station-consumer.error.log &

nohup spark-submit --master yarn --deploy-mode cluster --class com.tw.apps.StationApp --name StationTransformerNYC --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0  --driver-memory 500M --conf spark.executor.memory=2g --conf spark.cores.max=1 /tmp/tw-station-transformer-nyc_2.11-0.0.1.jar ${KAFKA_HOST}:2181 1>/tmp/station-transformer-nyc.log 2>/tmp/station-transformer-nyc.error.log &

echo "====Station Consumers Deployed===="
EOF

echo "====Deploy Station Mart Checker Dag to Airflow===="
echo "====Copy dags to airflow server===="
scp ./StationMartChecker/dags/station-mart-checker.py airflow${HOST_SUFFIX}.${TRAINING_COHORT}.training:/home/ec2-user/airflow/dags
echo "====Dags copied to airflow server===="

echo "====Create hive table===="
ssh hadoop@${EMR_MASTER_HOST} <<EOF
set -e

hive

CREATE SCHEMA IF NOT EXISTS mart;
CREATE EXTERNAL TABLE IF NOT EXISTS mart.station_mart
        (bikes_available INT,
         docks_available INT,
         is_renting BOOLEAN,
         is_returning BOOLEAN,
         last_updated BIGINT,
         stattion_id VARCHAR(100),
         name VARCHAR(100),
         latitude DOUBLE,
         longitude DOUBLE )
     ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
     LOCATION 'hdfs://${EMR_MASTER_HOST}/tw/stationMart/data'
     TBLPROPERTIES ('skip.header.line.count' = '1');
EOF