# frozen_string_literal: true

class CdmConnector < ApplicationService
  def initialize(*args)
    query = args.first[:query]
    query.gsub("/", " ")
    query = ERB::Util.url_encode(query)
    fields = "title!date"
    format = "json"

    @results = []

    @service_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmQuery/all/CISOSEARCHALL^#{query}^all^and/#{fields}/sortby/3/#{format}"
  end

  def call
    begin
      response = JSON.load(URI.open(@service_url))
      total_items = response.dig("pager", "total") || 0
      response["records"].each do |i|
        item = OpenStruct.new
        item.title = i.fetch("title")
        item.date = i.fetch("date")
        item.collection = i.fetch("collection")
        item.link = "https://digital.library.temple.edu/digital/collection#{i["collection"]}/id/#{i["pointer"]}"
        item.thumbnail = "https://digital.library.temple.edu/utils/ajaxhelper/?CISOROOT=#{i["collection"]}&CISOPTR=#{i["pointer"]}&action=2&DMSCALE=10&DMHEIGHT=340"
        @results << item
      end
    rescue StandardError => e
      total_items = 0
      Honeybadger.notify("Ran into error while try to process CDM: #{e.message}")
    end
    @results
  end
end
