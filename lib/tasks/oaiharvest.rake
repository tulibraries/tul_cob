require 'rsolr'
require 'nokogiri'
require 'tempfile'
require 'oai/alma'
require 'ruby-progressbar'

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
      file_paths = Oai::Alma.harvest
      puts "Records harvested to: #{file_paths}"
    end

    desc 'Conforms raw OAI MARC records to traject readable MARC records'
    task :conform, [:harvest_file] => :environment do |t, args|
      file_path = Oai::Alma.conform(args[:harvest_file])
      puts "MARC file: #{file_path}"
    end

    desc 'Conforms all raw OAI MARC records to traject readable MARC records'
    task :conform_all => :environment do
      log_path = File.join(Rails.root, 'log/fortytu.log')
      logger = Logger.new(log_path, 10, 1024000)
      begin
        oai_path = File.join(Rails.root, 'tmp', 'alma', 'oai', '*.xml')
        harvest_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
        progressbar = ProgressBar.create(:title => "Harvest ", :total => harvest_files.count, format: "%t (%c/%C) %a |%B|")
        harvest_files.each do |f|
          logger.info "MARC file: #{f}"
          file_path = Oai::Alma.conform(f)
          progressbar.increment
        end
      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      end
    end

    desc 'Ingest all readable MARC records'
    task :ingest_all => :environment do
      log_path = File.join(Rails.root, 'log/fortytu.log')
      logger = Logger.new(log_path, 10, 1024000)
      begin
        oai_path = File.join(Rails.root, 'tmp', 'alma', 'marc', '*.xml')
        marc_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
        marc_files.each_with_index do |f, i|
          logger.info "Index: traject -c app/models/traject_indexer.rb #{f}"
          `traject -c app/models/traject_indexer.rb #{f}`
          if ((i % 10) == 0)
            logger.info "Commit: traject -c app/models/traject_indexer.rb -x commit"
            `traject -c app/models/traject_indexer.rb -x commit`
          end
        end
        logger.info "Commit: traject -c app/models/traject_indexer.rb -x commit"
        `traject -c app/models/traject_indexer.rb -x commit`
      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      ensure
        `traject -c app/models/traject_indexer.rb -x commit`
        logger.info "Commit: traject -c app/models/traject_indexer.rb -x commit"
      end
    end
  end
end
