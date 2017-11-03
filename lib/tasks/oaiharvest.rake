# frozen_string_literal: true

require "rsolr"
require "nokogiri"
require "tempfile"
require "oai/alma"

namespace :fortytu do

  desc "Posts fixtures to Solr"
  task :ingest, [:marc_file] => :environment do |t, args|
    `traject -c app/models/traject_indexer.rb #{args[:marc_file]}`
    `traject -c app/models/traject_indexer.rb -x commit`
  end

  desc "Remove deleted items from Solr"
  task purge: :environment do
    solr = RSolr.connect url: Blacklight.connection_config[:url]
    delete_files_path = File.join(Rails.root, "tmp", "alma", "marc-delete", "*.xml")
    delete_files = Dir.glob(delete_files_path).select { |fn| File.file?(fn) }
    delete_files.each do |f|
      delete_doc = Nokogiri::XML(File.open(f))
      delete_doc.xpath("//xmlns:identifier").map do |id|
        solr.update data: "<delete><query>id:#{id.text.split(':').last}</query></delete>"
      end
    end
    solr.update data: "<commit/>"
  end

  namespace :oai do
    desc "Harvests OAI MARC records between optional start and end time from Alma."
    task :harvest, [:from, :to] => :environment do |t, args|
      file_paths = Oai::Alma.harvest(args)
      puts "Records harvested to: #{file_paths}"
    end

    desc "Conforms raw OAI MARC records to traject readable MARC records"
    task :conform, [:harvest_file] => :environment do |t, args|
      file_path = Oai::Alma.conform(args[:harvest_file])
      puts "MARC file: #{file_path}"
    end

    desc "Conforms all raw OAI MARC records to traject readable MARC records"
    task conform_all: :environment do
      log_path = File.join(Rails.root, "log/fortytu.log")
      logger = Logger.new(log_path, 10, 4096000)
      begin
        oai_path = File.join(Rails.root, "tmp", "alma", "oai", "*.xml")
        harvest_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
        harvest_files.each do |f|
          logger.info "MARC file: #{f}"
          Oai::Alma.conform(f)
        end
      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      end
    end

    desc "Ingest all readable MARC records"
    task ingest_all: :environment do
      main_logdir = File.join(Rails.root, "log/")
      main_log = File.join(main_logdir, "fortytu.log")
      logger = Logger.new(main_log, 10, 1024000)

      ingest_logdir = File.join(main_logdir, "ingest/")
      FileUtils::mkdir_p ingest_logdir

      batch_size = 10
      begin
        oai_path = File.join(Rails.root, "tmp", "alma", "marc", "*.xml")
        marc_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
        traject_commit = %W[traject -s
          log.file=#{main_log}
          -c app/models/traject_indexer.rb
          -x commit].join(" ")
        pids = []
        marc_files.each_with_index do |f, i|
          logger.info "Indexing  #{f}"
          ingest_log = File.join(ingest_logdir, File.basename(f, ".xml") + ".log")
          traject_index = %W[traject
            -s log.file=#{ingest_log}
            -c app/models/traject_indexer.rb
            #{f}].join(" ")
          pids << Process.spawn(traject_index)
          if ((i > 0) && (i % batch_size) == 0)
            logger.info "Wait for for spawned process completion"
            pids.each do |p|
              logger.info "Waiting for process #{p}"
              Process.waitpid(p)
            end
            pids.clear
          end
        end
      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      ensure
        logger.info "Commiting data"
        system(traject_commit)
      end
    end
  end
end
