# frozen_string_literal: true

desc "Run test suite"
task :ci, [:spec_args] do |_, args|
  Rake::Task["tul_cob:solr:load_fixtures"].invoke
  rspec_cmd = ["rspec", args[:spec_args]].compact.join(" ")
  passed = system(rspec_cmd)
  exit(1) unless passed
end

desc "Run solr and blacklight for interactive development"
task :server, [:rails_server_args] do |t, args|
  run_solr("dev", port: "8983") do
    Rake::Task["tul_cob:solr:load_fixtures"].invoke if ENV["DO_INGEST"]
    system "bundle exec rails s #{args[:rails_server_args]}"
  end
end

def run_solr(environment, solr_params)
  url = "http://lib-solr-mirror.princeton.edu/dist/lucene/solr/6.6.1/solr-6.6.1.zip"
  mirror_url = "http://lib-solr-mirror.princeton.edu/dist/"
  checksum = "http://lib-solr-mirror.princeton.edu/dist/lucene/solr/6.6.1/solr-6.6.1.zip.sha1"
  solr_params.merge!(url: url, checksum: checksum, mirror_url: mirror_url, ignore_checksum: true)
  solr_dir = File.join(File.expand_path(".", File.dirname(__FILE__)), "../../", "solr")

  SolrWrapper.wrap(solr_params) do |solr|
    ENV["SOLR_TEST_PORT"] = solr.port

    # additional solr configuration
    solr.with_collection(name: "blacklight-core-#{environment}", dir: File.join(solr_dir, "conf")) do
      solr.with_collection(name: "az-database", dir: File.join(solr_dir, "conf")) do
        solr.with_collection(name: "web-content", dir: File.join(solr_dir, "conf")) do
          puts "\n#{environment.titlecase} solr server running:
          catalog: http://localhost:#{solr.port}/solr/#/blacklight-core-#{environment}
          az-database: http://localhost:#{solr.port}/solr/#/az-database
          web-content: http://localhost:#{solr.port}/solr/#/web-content"

          puts "\n^C to stop"
          puts " "
          begin
            yield
          rescue Interrupt
            puts "Shutting down..."
            raise Interrupt
          end
        end
      end
    end
  end
end


desc "Reloads the Alma Electronic Notes"
task :reload_electronic_notes, [:path] => :environment do |_, args|
  puts "Running in #{Rails.env} environment."

  args.with_defaults(path: "/tmp")

  ["collection", "service"].each do |type|
    filename = Alma::ConfigUtils.filename(type, args[:path])
    abort("Missing required file #{filename}, aborting the reload.") unless File.exists? filename

    puts
    puts "Reloading the electronic #{type} notes from #{filename}..."

    notes = Alma::ConfigUtils.load_notes(type: type, path: filename)
    puts "Number of #{type} notes to be loaded: #{notes&.count.to_i}"

    store = JsonStore.find_or_initialize_by(name: "#{type}_notes")
    puts "Current number of #{type} notes: #{store.value&.count.to_i}"

    store.value = notes

    abort("Failed to reload #{type} notes") unless store.save

    puts "Delete the #{type}_notes cache..."
    Rails.cache.delete("#{type}_notes")
    puts
  end
end
