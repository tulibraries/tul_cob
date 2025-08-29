FROM solr:9.8.1
COPY ./solr/configs/ /opt/solr/configs

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]
