#!/usr/bin/env bash
set -e

docker pull solr:$SOLR_VERSION
docker run -p 8983:8983 \
  -v $PWD/solr/conf:/opt/solr/server/solr/configsets/default/conf \
  -d solr:$SOLR_VERSION bash \
  -c "precreate-core az-database; precreate-core blacklight-core-dev; precreate-core web-content; exec solr -f"

# Health Check the Solr Server
curl --retry 10 --retry-connrefused http://localhost:8983
