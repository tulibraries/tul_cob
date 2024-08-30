#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "httparty"
require "ipaddr"
require "sqlite3"
require "json"
require "fileutils"

# Get the file path from the command line arguments
csv_file = ARGV[0]

if csv_file.nil?
  puts "A CSV file with ips to get info for is required."
  puts "If you're at Temple University, then the file is the report found at this link:
  https://osd.k8s.temple.edu/app/data-explorer/discover/#/view/f54f4550-062e-11ef-8715-19c61fecee09?_a=(discover:(columns:!(httpRequest.latency,httpRequest.requestUrl,httpRequest.remoteIp),isDirty:!f,savedSearch:f54f4550-062e-11ef-8715-19c61fecee09,sort:!()),metadata:(indexPattern:'58ae70e0-f0fe-11ed-9530-11381efde89a',view:discover))&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-15h,to:now))&_q=(filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:'83619360-83ea-11ee-b5c6-3b86f1edbc73',key:kubernetes.namespace_name,negate:!f,params:(query:Nginx),type:phrase),query:(match_phrase:(kubernetes.namespace_name:Nginx))),('$state':(store:appState),meta:(alias:!n,disabled:!f,index:'83619360-83ea-11ee-b5c6-3b86f1edbc73',key:proxyUpstreamName,negate:!f,params:(query:%25librarysearch%25),type:phrase),query:(match_phrase:(proxyUpstreamName:%25librarysearch%25))),('$state':(store:appState),meta:(alias:!n,disabled:!f,index:'83619360-83ea-11ee-b5c6-3b86f1edbc73',key:httpRequest.requestUrl,negate:!t,params:(query:%25assets%25),type:phrase),query:(match_phrase:(httpRequest.requestUrl:%25assets%25)))),query:(language:kuery,query:''))"
  exit!
end

# Create a connection to the SQLite3 database (creates the file if it doesn't exist)
DB_PATH = File.expand_path("~/.ipinfo/ip-info.db")
FileUtils.mkdir_p(File.dirname(DB_PATH))

DB = SQLite3::Database.new DB_PATH

# Create a table for storing the IP addresses
create_table_sql = <<-SQL
  CREATE TABLE IF NOT EXISTS ip_addresses (
    id INTEGER PRIMARY KEY,
    ip TEXT UNIQUE,
    org TEXT,
    range TEXT
  );
SQL

DB.execute(create_table_sql)

def save_ipinfo(ip_info)
  keys = ip_info.keys.join(", ")
  holders = ip_info.keys.map { "?" }.join(", ")
  values = ip_info.values

  begin
    DB.execute("INSERT INTO ip_addresses (#{keys}) VALUES (#{ holders })", values)
  rescue
  end
end

def get_ipinfo(ip_address)
  get_ipinfo_from_db(ip_address) or
    get_ipinfo_from_server(ip_address)
end

def get_ipinfo_from_db(ip_address)
  result = DB.execute("SELECT * FROM ip_addresses WHERE ip = ?", [ip_address]).first
  if result
    ip_info = { 'ip': result[1], 'org': result[2] }
    ip_info.merge!(range: result[3]) if result[3]
    print "."
  end
  return ip_info
end

def get_ipinfo_from_server(ip, token = ENV["IPINFO_TOKEN"])
  url = "https://ipinfo.io/#{ip}/json"
  url += "?token=#{token}" if token

  response = HTTParty.get(url)
  if response.code == 200
    data = response.parsed_response.slice("ip", "org", "range")
    print ":"

    save_ipinfo(data)
    return data
  else
    puts "Failed to retrieve info for IP #{ip}: #{response.body}"
    return nil
  end
end

def private_ip?(ip)
  private_ranges = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16")
  ]

  ip = IPAddr.new(ip)
  private_ranges.any? { |range| range.include?(ip) }
end

# Initialize an empty array to hold ips we are processing.
ips = []
# Initialize cache to keep track of what we have processed.
ip_info = {}

# Get IPs from CSV file.
CSV.foreach(csv_file, headers: true) do |row|
  ip = row["httpRequest\\.remoteIp"]
  ips << ip unless private_ip?(ip)
end

stats = ips.sort.reduce({}) do |acc, ip|
  if !ip_info[ip]
    ip_info[ip] = get_ipinfo(ip)
  end

  org = ip_info[ip]["org"] || ip_info[ip][:org]

  # What are the ips associated to a specific org?
  if acc[org]
    acc[org]["ips"] << ip
  else
    acc[org] = {}
    acc[org]["ips"] = [ip]
  end

  # How many of the total hits come from this specific org?
  acc[org]["percent"] = acc[org]["ips"].count.to_f / ips.count * 100
  acc
end

def take_top(stats, count = 10)
  stats
    .sort_by { |org| _, info = org ; info["percent"] }
    .reverse
    .take(count)
end

puts
puts
puts "Percent Totals of #{ips.count} Requests by Organization (top 10):"
puts "-------------------------------"
take_top(stats).each do |org, info|
  percent = format("%.2f", info["percent"])
  puts "#{percent}%: #{org}"
end

def cidr(ips)
  ips.flatten
    .map { |ip| parts = ip.split("."); "#{parts[0]}.#{parts[1]}.0.0/16" }
    .sort.uniq.join(",")
end

def org_ips(org)
  ips = DB.execute("select ip from ip_addresses where org = '#{org}';")
end

# Output of CIDR lists
take_top(stats).each do |org, _|
  puts
  puts "CIDR list to match all known '#{org}' IPs:"
  puts cidr(org_ips(org))
end

DB.close
