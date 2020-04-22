FROM solr:8.3.0
COPY ./solr/configs/ /opt/solr/configs

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]