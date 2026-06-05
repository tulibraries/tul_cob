# frozen_string_literal: true

require "rsolr"
require "uri"
require "cgi"

def env_with_basic_auth(url_env_key, url)
  return {} unless url

  env = { url_env_key => url }
  user, password = solr_credentials_from(url)
  env["SOLR_AUTH_USER"] = user if user
  env["SOLR_AUTH_PASSWORD"] = password if password
  env
end

def solr_credentials_from(url)
  uri = URI.parse(url)
  user = uri.user && CGI.unescape(uri.user)
  password = uri.password && CGI.unescape(uri.password)
  [user, password]
rescue URI::InvalidURIError
  [nil, nil]
end

namespace :tul_cob do
  namespace :solr do

    desc "Posts fixtures to Solr"
    task :load_fixtures, [:filepath] => [:environment] do |t, args|
      solr_url = Blacklight::Configuration.new.connection_config[:url]

      if solr_url.match("solrcloud.tul-infra.page")
        abort "Cannot run :load_fixtures task on production server"
      end

      puts "Prepping spec fixtures for ingest..."
      fixtures = Dir.glob(args.fetch(:filepath, "spec/fixtures/*_marc.xml"))

      if ENV["DO_INGEST"].present?
        puts "Adding sample data to ingest prep..."
        fixtures += Dir.glob("sample_data/**/*.xml").sort
      end

      puts "Loading catalog fixtures..."
      solr_url = Blacklight::Configuration.new.connection_config[:url]
      catalog_env = env_with_basic_auth("SOLR_URL", solr_url)
      fixtures.sort.reverse.each  do |file|
        puts "Ingesting #{file}"
        system(catalog_env, "cob_index", "ingest", file)
      end
      solr = RSolr.connect url: solr_url
      solr.commit

      if args[:filepath]
        # Short circuit if filepath is set because that's only safe for
        # ingesting marc files.
        next
      end

      puts "Loading cob_az_index fixtures..."
      az_url = Blacklight::Configuration.new.connection_config[:az_url]
      az_env = env_with_basic_auth("SOLR_AZ_URL", az_url)
      system(az_env, "cob_az_index", "ingest", "--use-fixtures", "--delete")


      puts "Loading cob_web_index fixtures..."
      web_url = Blacklight::Configuration.new.connection_config[:web_content_url]
      web_env = env_with_basic_auth("SOLR_WEB_URL", web_url)
      system(web_env, "cob_web_index", "ingest", "--use-fixtures", "--delete")
    end

    desc "Delete all items from Solr"
    task :clean => [:environment] do
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
  catalog_env = env_with_basic_auth("SOLR_URL", solr_url)

  if solr_url.match("solrcloud.tul-infra.page")
    abort "Cannot run :load_fixtures task on production server"
  end

  if file && file.match?(/databases.json/)
    az_url = Blacklight::Configuration.new.connection_config[:az_url]
    az_env = env_with_basic_auth("SOLR_AZ_URL", az_url)
    system(az_env, "cob_az_index", "ingest", "--use-fixtures", "--delete")
  elsif file && file.match(/\/web_content/)
    web_url = Blacklight::Configuration.new.connection_config[:web_content_url]
    web_env = env_with_basic_auth("SOLR_WEB_URL", web_url)
    system(web_env, "cob_web_index", "ingest", "--use-fixtures", "--delete")
  elsif file
    system(catalog_env, "cob_index", "ingest", "--commit", file)
  else
    Dir.glob("sample_data/**/*.xml").sort.each do |f|
      system(catalog_env, "cob_index", "ingest", f)
    end

    system(catalog_env, "cob_index", "commit")
  end
end
