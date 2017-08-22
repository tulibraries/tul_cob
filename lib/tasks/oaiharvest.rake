require 'rsolr'
require 'nokogiri'
require 'tempfile'
require 'oai/alma'

namespace :fortytu do

  desc 'Posts fixtures to Solr'
  task :ingest, [:marc_file] => :environment do |t, args|
    `traject -c app/models/traject_indexer.rb #{args[:marc_file]}`
    `traject -c app/models/traject_indexer.rb -x commit`
  end

  desc 'Delete fixtures from Solr'
  task :clean => :environment do
    solr = RSolr.connect :url => Blacklight.connection_config[:url]
    solr.update data: '<delete><query>*:*</query></delete>'
    solr.update data: '<commit/>'
  end

  namespace :oai do
    desc 'Harvests OAI MARC records from Alma'
    task :harvest do
      file_path = Oai::Alma.harvest
      puts "Records harvested to: #{file_path}"
    end

    desc 'Conforms raw OAI MARC records to traject readable MARC records'
    task :conform, [:harvest_file] => :environment do |t, args|
      file_path = Oai::Alma.conform(args[:harvest_file])
      puts "MARC file: #{file_path}"
    end

    desc 'Conforms all raw OAI MARC records to traject readable MARC records'
    task :conform_all => :environment do
      oai_path = File.join(Rails.root, 'tmp', 'alma', 'oai', '*.xml')
      harvest_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
      harvest_files.each do |f|
        file_path = Oai::Alma.conform(f)
        puts "MARC file: #{file_path}"
      end
    end

  end
end
