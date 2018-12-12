FROM solr:6.6.1
COPY ./solr/conf /opt/solr/conf
RUN precreate-core az-database /opt/solr/conf
