require 'solr_wrapper' unless Rails.env.production?

desc 'Run test suite'
task :ci do
  if Rails.env.test?
    run_solr('test', { port: '8985' }) do
      Rake::Task['fortytu:solr:load_fixtures'].invoke
      Rake::Task['spec'].invoke
    end
  else
    system('rake ci RAILS_ENV=test')
  end
end

desc 'Run selected specs (Use with Guard)'
task :rspec, [:spec_args] do |t, args|
  if Rails.env.test?
    run_solr('test', { port: '8985' }) do
      Rake::Task['fortytu:solr:load_fixtures'].invoke
      rspec_cmd = "rspec #{args[:spec_args]}"
      system(rspec_cmd)
    end
  else
    system("rake rspec[#{args[:spec_args]}] RAILS_ENV=test")
  end
end

desc 'Run solr and blacklight for interactive development'
task :server, [:rails_server_args] do |t, args|
  run_solr('development', { port: '8983' }) do
    Rake::Task['fortytu:solr:load_fixtures'].invoke
    system "bundle exec rails s #{args[:rails_server_args]}"
  end
end

def run_solr(environment, solr_params)
  solr_dir = File.join(File.expand_path('.', File.dirname(__FILE__)), '../../', 'solr')
  SolrWrapper.wrap(solr_params) do |solr|
    ENV['SOLR_TEST_PORT'] = solr.port

    # additional solr configuration
    solr.with_collection(name: "blacklight-core-#{environment}", dir: File.join(solr_dir, 'conf')) do
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
