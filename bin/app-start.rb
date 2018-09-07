# frozen_string_literal: true

require "fileutils"
require "rsolr"

# Map example config files to use in development.
Dir.glob("config/*")
  .select { |p| p.match(/example$/) }
  .each do |p|
  src = p
  dest = p.gsub(".example", "")
  FileUtils.copy_file(src, dest) unless File.exist? dest
end

# Rails is temperamental if pid is left around.
server_pid = "tmp/pids/server.pid"
File.delete server_pid if File.exist? server_pid

# Start rails app but do not block the rest of the script.
`rails db:migrate`
`yarn`
exec("rails s -p 3000 -b '0.0.0.0'") if fork == nil

# Next, provision with test data.
# (If we do this first it works, but site will be blank until rails app loads).
# But only ingest if solr is empty
def solr_empty?
  solr = RSolr.connect url: "http://solr:8983/solr/blacklight"
  response = solr.get("select", params: { q: "test", rows: 0 })
  response["response"]["numFound"] == 0
end

if solr_empty?
  `rake fortytu:solr:load_fixtures`
  `rake ingest`
end

# Wait for rails server to shutdown before stopping the process.
Process.wait
