# frozen_string_literal: true

# rubocop:disable BlockLength
namespace :docker do
  task build: :config do
    server_pid = 'tmp/pids/server.pid'
    File.delete server_pid if File.exist? server_pid
    IO.popen('docker-compose build') do |io|
      line = io.gets
      while line
        print line
        line = io.gets
      end
      io.close
    end
  end

  task up: :build do
    print `docker-compose up -d`
    Rake::Task['docker:init'].invoke
    Rake::Task['docker:ps'].invoke
  end

  task :config do
    Dir.glob('config/*')
       .select { |p| p.match(/example$/) }
       .each do |p|
      src = p
      dest = p.gsub('.example', '')
      copy_file(src, dest) unless File.exist? dest
    end
  end

  task :stop do
    print `docker-compose stop`
  end

  task :ps do
    print `docker-compose ps`
  end

  task :init do
    print `docker-compose exec app rails db:migrate`
    print `docker-compose exec app rake fortytu:solr:load_fixtures`
  end
end
