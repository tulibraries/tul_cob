ip-info.rb
==========

This script will analyze a CSV file with a column of ips labeled 'httpRequest\\.remoteIp'
and it will generate a report of the top ten orgs who's ips have been determined to make
the most requests. It will also generate CIDR lists that match these ips.

This script will keep a copy of unique ips and info about them in an sqlite database that it
stores at ~/.ipinfo/ip-info.db

This script uses the ipinfo.io site to collect information about ips that it analyzes.
You can set a IPINFO_TOKEN environment variable and it will use that when making requests
to that service.

If you do not set and use an IPINFO_TOKEN you will be limited to 1000 requests per day.


