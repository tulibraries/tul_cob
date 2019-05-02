#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path("../../config/environment",  __FILE__)

indexer = Traject::Indexer::MarcIndexer.new("solr_writer.commit_on_close": true)
indexer.load_config_file("./lib/traject/indexer_config.rb")
indexer.process(StringIO.new(open(ARGV[0]).read))
