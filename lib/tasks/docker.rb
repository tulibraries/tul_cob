# frozen_string_literal: true

require "json"

# rubocop:disable BlockLength
namespace :docker do
  task :up do
    print `docker-compose -f docker-compose.yml -f cli.docker-compose.yml up -d --build`
    Rake::Task["docker:ps"].invoke
  end

  task :down do
    print `docker-compose down`
  end

  task :ps do
    print `docker-compose ps`
  end

  def get_local_port(service = "app", port = 3000)
    (docker, _) = JSON.parse(`docker inspect $(docker-compose ps --quiet #{service})`)

    docker&.dig("NetworkSettings", "Ports", "#{port}/tcp")
      &.first
      &.dig("HostPort")
  end

  task :open do
    port = get_local_port("app", "3000")
    `open http://localhost:#{port}`
  end


  task :open_solr do
    port = get_local_port("solr", 8983)
    `open http://localhost:#{port}`
  end
end
