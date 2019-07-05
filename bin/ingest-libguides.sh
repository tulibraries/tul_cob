#! /usr/bin/env bash

SOLR_URL=$SOLR_AZ_URL SOLR_DISABLE_UPDATE_DATE_CHECK=yes traject -c lib/traject/databases_az_indexer_config.rb tmp/cache/databases.json

curl $SOLR_AZ_URL/update?commit=true
