# frozen_string_literal: true

# rubocop:disable BlockLength
namespace :docker do
  task :up do
    print `docker-compose up -d --build`
    Rake::Task["docker:ps"].invoke
  end

  task :down do
    print `docker-compose`
  end

  task :ps do
    print `docker-compose ps`
  end
end
