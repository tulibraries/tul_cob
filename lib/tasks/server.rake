# frozen_string_literal: true

desc "Run test suite"
task :ci, [:spec_args] do |_, args|
  Rake::Task["tul_cob:solr:load_fixtures"].invoke
  rspec_cmd = ["rspec", args[:spec_args]].compact.join(" ")
  passed = system(rspec_cmd)
  exit(1) unless passed
end

desc "Reloads the Alma Electronic Notes"
task :reload_electronic_notes, [:path] => :environment do |_, args|
  puts "Running in #{Rails.env} environment."

  args.with_defaults(path: "/tmp")

  ["collection", "service"].each do |type|
    filename = Alma::ConfigUtils.filename(type, args[:path])
    abort("Missing required file #{filename}, aborting the reload.") unless File.exist? filename

    puts
    puts "Reloading the electronic #{type} notes from #{filename}..."

    notes = Alma::ConfigUtils.load_notes(type:, path: filename)
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
