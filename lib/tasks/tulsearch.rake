# frozen_string_literal: true

require "rsolr"

namespace :fortytu do
  namespace :solr do

    desc "Posts fixtures to Solr"
    task :load_fixtures, [:filepath] do |t, args|
      fixtures = args.fetch(:filepath, "spec/fixtures/*.xml")
      Dir.glob(fixtures).sort.reverse.each do |file|
        `traject -c #{Rails.configuration.traject_indexer} #{file}`
      end
      `traject -c #{Rails.configuration.traject_indexer} -x commit`

      az_url = Blacklight::Configuration.new.connection_config[:az_url]
      `SOLR_URL=#{az_url} traject -c lib/traject/databases_az_indexer_config.rb spec/fixtures/databases.json`

      `traject -c #{Rails.configuration.traject_indexer} -x commit`
      `SOLR_URL=#{az_url} traject -c lib/traject/databases_az_indexer_config.rb -x commit`

      web_content_url = Blacklight::Configuration.new.connection_config[:web_content_url]
      fixtures = args.fetch(:filepath, "spec/fixtures/web_content_data/*.json")
      Dir.glob(fixtures).sort.reverse.each do |file|
        `SOLR_URL=#{web_content_url} traject -c lib/traject/web_content_indexer_config.rb #{fixtures}`
      end

      `SOLR_URL=#{web_content_url} traject -c lib/traject/web_content_indexer_config.rb -x commit`
    end

    desc "Delete all items from Solr"
    task :clean do
      solr = RSolr.connect url: Blacklight.connection_config[:url]
      solr.update data: "<delete><query>*:*</query></delete>"
      solr.update data: "<commit/>"
    end
  end
end

desc "Ingest a single file or all XML files in the sammple_data folder"
task :ingest, [:filepath] => [:environment] do |t, args|
  file = args[:filepath]
  if file && file.match?(/databases.json/)
    az_url = Blacklight::Configuration.new.connection_config[:az_url]
    `SOLR_URL=#{az_url} traject -c lib/traject/databases_az_indexer_config.rb #{file}`
    `SOLR_URL=#{az_url} traject -c #{Rails.configuration.traject_indexer} -x commit`
  elsif file
    `traject -c #{Rails.configuration.traject_indexer} #{args[:filepath]}`
  else
    Dir.glob("sample_data/**/*.xml").sort.each do |f|
      `traject -c #{Rails.configuration.traject_indexer} #{f}`
    end
  end

  `traject -c #{Rails.configuration.traject_indexer} -x commit`
end
