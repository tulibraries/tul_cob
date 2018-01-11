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

# Start rails app but do not block the rest of the script.
`rails db:migrate`
exec("rails s -p 3000 -b '0.0.0.0'") if fork == nil

# Next, provision with test data.
# (If we do this first it works, but site will be blank until rails app loads).
`rake fortytu:solr:load_fixtures`
`rake ingest`

# Wait for rails server to shutdown before stopping the process.
Process.wait
