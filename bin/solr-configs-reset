#!/usr/bin/env bash

cp /opt/solr/configs/tul_cob-catalog-solr/solrconfig.xml /var/solr/data/blacklight/
cp /opt/solr/configs/tul_cob-catalog-solr/schema.xml /var/solr/data/blacklight/
curl 'http://localhost:8983/solr/admin/cores?action=RELOAD&core=blacklight'
cp /opt/solr/configs/tul_cob-az-solr/solrconfig.xml /var/solr/data/az-database/
cp /opt/solr/configs/tul_cob-az-solr/schema.xml /var/solr/data/az-database/
curl 'http://localhost:8983/solr/admin/cores?action=RELOAD&core=az-database'
cp /opt/solr/configs/tul_cob-web-solr/solrconfig.xml /var/solr/data/web-content/
cp /opt/solr/configs/tul_cob-web-solr/schema.xml /var/solr/data/web-content/
curl 'http://localhost:8983/solr/admin/cores?action=RELOAD&core=web-content'
