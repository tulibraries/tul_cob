#!/usr/bin/env ruby

`ENV_RAILS=development bundle exec cob_index ingest #{ARGV[0]}`
