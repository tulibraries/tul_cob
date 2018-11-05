# frozen_string_literal: true

require "rsolr"
require "nokogiri"
require "tempfile"
require "oai/alma"
require "time"

namespace :fortytu do

  desc "Posts fixtures to Solr"
  task :ingest, [:marc_file] => :environment do |t, args|
    `traject -c #{Rails.configuration.traject_indexer} #{args[:marc_file]}`
    `traject -c #{Rails.configuration.traject_indexer} -x commit`
  end

  desc "Remove deleted items from Solr"
  task purge: :environment do
    solr = RSolr.connect url: Blacklight.connection_config[:url],
      read_timeout: 120
    delete_files_path = File.join(Rails.root, "tmp", "alma", "marc-delete", "*.xml")
    delete_files = Dir.glob(delete_files_path).select { |fn| File.file?(fn) }
    ids = []
    delete_files.each do |f|
      delete_doc = Nokogiri::XML(File.open(f))
      delete_doc.remove_namespaces!
      delete_doc.xpath("//identifier").map do |id|
        ids << id.text.split(":").last
      end
    end
    puts "Purging the following IDs:"
    puts ids
    solr.delete_by_id ids
  end

  namespace :oai do

    desc "Run the oai harvest from a Jenkins Job"
    task :jenkins_harvest, [:from, :to, :use_cache] do |task, args|
      from = args[:from] || Jenkins.last_build_time
      to = args[:to] || Time.now
      from, to = [from, to].map { |t| t.to_time.utc.iso8601 }

      # Run the harvester.
      if !args[:use_cache]
        # Delete the previous build's marc_xml_files.
        Dir.glob("tmp/alma/**/*.xml").each { |file| File.delete file }
        Rake::Task["fortytu:oai:harvest"].invoke(from, to)
        Rake::Task["fortytu:oai:conform_all"].invoke()
      end

      Rake::Task["fortytu:oai:ingest_all"].invoke()
      Rake::Task["fortytu:purge"].invoke()

      # Check the build for errors.
      if File.file? "log/fortytu.log.error"

        # Print and archive the Error logs
        # TODO: DRY up log file determination
        main_logdir = File.join(Rails.root, "log/")
        main_log = File.join(main_logdir, "fortytu.log")
        error_log = "#{main_log}.error"

        puts "Errors:"
        File.open(error_log) do |file|
          file.each_line { |line| puts line }
        end
        File.rename(error_log, "#{error_log}-#{timestamp}")

        # Fail this build
        exit 1
      end
    end

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
      logger = Logger.new("| tee #{log_path}", 10, 4096000)
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
      logger = Logger.new("| tee #{main_log}", 10, 1024000)

      ingest_logdir = File.join(main_logdir, "ingest/")
      FileUtils::mkdir_p ingest_logdir

      batch_size = 10
      begin
        oai_path = File.join(Rails.root, "tmp", "alma", "marc", "*.xml")
        marc_files = Dir.glob(oai_path).select { |fn| File.file?(fn) }
        pids = []
        marc_files.each_with_index do |f, i|
          logger.info "Indexing  #{f}"
          ingest_log = File.join(ingest_logdir, File.basename(f, ".xml") + ".log")
          traject_index = %W[traject
            -s log.file=#{ingest_log}
            -c #{Rails.configuration.traject_indexer}
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
      end
    end
  end
end
