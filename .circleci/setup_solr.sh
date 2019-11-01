#!/usr/bin/env bash

docker pull solr:$SOLR_VERSION
docker run -p 8983:8983 \
  -v ~/project/solr/conf:/opt/solr/server/solr/configsets/_default \
  -d solr:$SOLR_VERSION bash \
  -c "precreate-core az-database; precreate-core blacklight-core-dev; precreate-core web-content; exec solr -f"

# Health Check the Solr Server
sleep 10

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8983/solr/blacklight-core-dev/admin/ping)

while [[ "$STATUS" != "200" ]]; do
  echo waiting for solr setup to complete or equal 200.
  echo "currenlty: $STATUS"
  sleep 5

  if [ "$STATUS" == "500" ]; then
    RESP=$(curl -s http://localhost:8983/solr/blacklight-core-dev/admin/ping)
    echo $RESP
    exit 1
  fi

  # Add TimeStamp to avoid possible caching layer issues.
  TIMESTAMP=$(date +"%d_%m_%Y_%H_%M_%S")
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8983/solr/blacklight-core-dev/admin/ping?timestamp=$TIMESTAMP)
done
