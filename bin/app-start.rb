# frozen_string_literal: true

# Map example config files to use in development.
Dir.glob("config/*")
  .select { |p| p.match(/example$/) }
  .each do |p|
  src = p
  dest = p.gsub(".example", "")
  copy_file(src, dest) unless File.exist? dest
end

# Rails is temperamental if pid is left around.
server_pid = "tmp/pids/server.pid"
File.delete server_pid if File.exist? server_pid

# Start rails app
`rails s -p 3000 -b '0.0.0.0'`

# Provision with test data.
`rails db:migrate`
`rake fortytu:solr:load_fixtures`
`rake ingest`
