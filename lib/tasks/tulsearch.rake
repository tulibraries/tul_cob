# frozen_string_literal: true

require "rsolr"

namespace :tul_cob do
  namespace :solr do

    desc "Posts fixtures to Solr"
    task :load_fixtures, [:filepath] do |t, args|
      fixtures = Dir.glob(args.fetch(:filepath, "spec/fixtures/*_marc.xml"))

      if ENV["RELEVANCE"]
        fixtures += Dir.glob("spec/relevance/fixtures/*.xml")
      end

      if ENV["DO_INGEST"]
        fixtures += Dir.glob("sample_data/**/*.xml").sort
      end

      solr_url = Blacklight::Configuration.new.connection_config[:url]
      fixtures.sort.reverse.each  do |file|
        `SOLR_URL=#{solr_url} cob_index ingest #{file}`
      end
      solr = RSolr.connect url: solr_url
      solr.commit

      if args[:filepath]
        # Short circuit if filepath is set because that's only safe for
        # ingesting marc files.
        next
      end

      az_url = Blacklight::Configuration.new.connection_config[:az_url]
      `SOLR_AZ_URL=#{az_url} cob_az_index ingest --use-fixtures --delete`

      web_url = Blacklight::Configuration.new.connection_config[:web_content_url]
      `SOLR_WEB_URL=#{web_url} cob_web_index ingest --use-fixtures --delete`
    end

    desc "Delete all items from Solr"
    task :clean do
      solr = RSolr.connect url: Blacklight.connection_config[:url], update_format: :xml
      solr.update data: "<delete><query>*:*</query></delete>"
      solr.update data: "<commit/>"
    end
  end
end

desc "Ingest a single file or all XML files in the sammple_data folder"
task :ingest, [:filepath] => [:environment] do |t, args|
  file = args[:filepath]
  solr_url = Blacklight::Configuration.new.connection_config[:url]

  if file && file.match?(/databases.json/)
    az_url = Blacklight::Configuration.new.connection_config[:az_url]
    `SOLR_AZ_URL=#{az_url} cob_az_index ingest --use-fixtures --delete`
  elsif file && file.match(/\/web_content/)
    web_url = Blacklight::Configuration.new.connection_config[:web_content_url]
    `SOLR_WEB_URL=#{web_url} cob_web_index ingest --use-fixtures --delete`
  elsif file
    `SOLR_URL=#{solr_url} cob_index ingest --commit #{args[:filepath]}`
  else
    Dir.glob("sample_data/**/*.xml").sort.each do |f|
      `SOLR_URL=#{solr_url} cob_index ingest #{f}`
    end

    `SOLR_URL=#{solr_url} cob_index commit`
  end
end
