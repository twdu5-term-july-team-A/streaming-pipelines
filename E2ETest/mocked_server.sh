#!/usr/bin/env bash
docker run -p 2525:2525 -p 4545:4545 -d andyrbell/mountebank
./wait_for_service.sh http://localhost:2525/imposters
curl -X DELETE http://localhost:2525/imposters/4545
curl -X POST -d @./stubs.json http://localhost:2525/imposters

