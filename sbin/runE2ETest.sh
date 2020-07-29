#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "====Building Producer JARs===="
$DIR/../CitibikeApiProducer/gradlew -p $DIR/../CitibikeApiProducer clean bootJar
echo "====Building Consumer JARs===="
cd $DIR/../StationConsumer && sbt package
echo "====Running docker-compose===="
$DIR/../docker/docker-compose.sh --project-directory $DIR/../docker -f $DIR/../docker/docker-compose-test.yml up --build -d

docker build -t e2e-test $DIR/../E2ETest

docker run \
  --network=streamingdatapipeline_streaming-data-internal \
  -v ~/.ivy2:/root/.ivy2:rw \
  -it  e2e-test \
  /bin/bash -c "cd /E2ETest && sbt test"

if [ $? -ne 0 ]
then
  echo "Test Failed"
  exit 255
else
  echo "Test Passed"
fi


