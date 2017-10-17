# frozen_string_literal: true

require "open-uri"

class BentoSearch::PrimoEngine
  include BentoSearch::SearchEngine

  @@per_page = 10

  attr_accessor :query

  def search_implementation(args)
    @query = args.fetch(:query, "")

    results = BentoSearch::Results.new

    primo_results = search_primo
    primo_results["docs"].each do |doc|
      results << conform_to_bento_result(doc)
    end
    results
  end

  def search_primo
    puts api_url
    JSON.parse(open(api_url).read)
  end

  def api_url
    params = {
      q: "any,contains,#{@query}",
      apikey: configuration.apikey,
      limit: @@per_page,
      scope: configuration.scope,
      vid: configuration.vid
    }
    URI::HTTPS.build(host: configuration.api_base_url, path: "/primo/v1/pnxs", query: params.to_query).to_s
  end

  def conform_to_bento_result(item)
    BentoSearch::ResultItem.new(title: item.fetch("title", ""),
      authors: authors(item),
      link: build_primo_url(item))
  end


  def authors(item)
    item.values_at("creator", "contributor")
      .flatten
      .compact
      .uniq
      .map { |creator| BentoSearch::Author.new(display: creator) }
  end


  def build_primo_url(primo_doc)
    "#{configuration.web_ui_base_url}#{primo_doc['pnxId']}&context=L&vid=#{configuration.vid}&search_scope=default_scope&tab=default_tab&lang=en_US"
  end
end
