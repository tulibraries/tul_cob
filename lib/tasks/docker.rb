# frozen_string_literal: true

namespace :docker do
  task :build do
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
    Rake::Task['docker:ps'].invoke
  end

  task :stop do
    print `docker-compose stop`
  end

  task :ps do
    print `docker-compose ps`
  end
end
