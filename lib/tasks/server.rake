# frozen_string_literal: true

require "solr_wrapper" unless Rails.env.production?

desc "Run test suite"
task :ci do
  ENV["DO_INGEST"] = "true"
  system "bundle exec solr_wrapper clean"
  Rake::Task["rspec"].invoke
end


desc "Run selected specs (Use with Guard)"
task :rspec, [:spec_args] do |t, args|
  passed = true
  if Rails.env.test?
    run_solr("test", port: "8985", solr_options: {STOP.KEY: "stopkey"}) do
      Rake::Task["fortytu:solr:load_fixtures"].invoke if ENV["DO_INGEST"]
      rspec_cmd = ["rspec", args[:spec_args]].compact.join(" ")
      passed = system(rspec_cmd)
    end
  else
    passed = system("rake rspec[#{args[:spec_args]}] RAILS_ENV=test")
  end
  exit(1) unless passed
end

desc "Run solr and blacklight for interactive development"
task :server, [:rails_server_args] do |t, args|
  run_solr("dev", port: "8983") do
    Rake::Task["fortytu:solr:load_fixtures"].invoke if ENV["DO_INGEST"]
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
      puts "\n#{environment.titlecase} solr server running: http://localhost:#{solr.port}/solr/#/blacklight-core-#{environment}"
      puts "\n^C to stop"
      puts " "
      begin
        yield
      rescue Interrupt
        puts "Shutting down..."
      end
    end
  end
end
