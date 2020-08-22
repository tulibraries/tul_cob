# frozen_string_literal: true

OkComputer::Registry.register "solr-catalog",
  OkComputer::SolrCheck.new(ENV["SOLR_URL"])

OkComputer::Registry.register "solr-az",
  OkComputer::SolrCheck.new(ENV["SOLR_AZ_URL"])

OkComputer::Registry.register "solr-web-content",
  OkComputer::SolrCheck.new(ENV["SOLR_WEB_CONTENT_URL"])
