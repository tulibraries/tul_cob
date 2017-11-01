# frozen_string_literal: true

require "rsolr"

namespace :fortytu do
  namespace :solr do

    desc "Posts fixtures to Solr"
    task :load_fixtures do
      Rake::Task["ingest"].invoke("spec/fixtures/marc_fixture.xml")
    end

    desc "Delete all items from Solr"
    task :clean do
      solr = RSolr.connect url: Blacklight.connection_config[:url]
      solr.update data: "<delete><query>*:*</query></delete>"
      solr.update data: "<commit/>"
    end
  end
end

desc 'Ingest a single file into solr and commit'
task :ingest, [:filepath] => [:environment] do |t, args|
  args.with_defaults(filepath: "sample_data/alma_bibs.xml")
  `traject -c app/models/traject_indexer.rb #{args[:filepath]}`
  `traject -c app/models/traject_indexer.rb -x commit`
end

