#!/usr/bin/env bash
docker pull solr:$SOLR_VERSION
docker run -p 8983:8983 \
  -v ~/project/solr/conf:/opt/solr/server/solr/configsets/_default \
  -d solr:$SOLR_VERSION bash \
  -c "precreate-core az-database; precreate-core blacklight-core-dev; precreate-core web-content; exec solr -f"

# Health Check the Solr Server
wget --retry-connrefused --waitretry=5 \
  --retry-on-http-error=503 \
  --read-timeout=20 --timeout=15 -t 5 -O - \
  http://localhost:8983/solr/blacklight-core-dev/admin/ping
