#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "====Destroying Local===="
$DIR/../docker/docker-compose.sh --project-directory $DIR/../docker -f $DIR/../docker/docker-compose.yml down