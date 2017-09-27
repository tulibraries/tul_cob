require 'open-uri'

class BentoSearch::PrimoEngine
  include BentoSearch::SearchEngine

  def search_implementation(args)
    results = BentoSearch::Results.new

    primo_results = search_primo({q: args[:query]})

    primo_results['docs'].each do |doc|
      result = BentoSearch::ResultItem.new({
        title: doc.fetch("title", ""),
        authors: doc.fetch("creator", []).map { |creator| BentoSearch::Author.new({display: creator})},
        link: build_primo_url(doc) })
      results << result
    end

    results
  end

  def search_primo(args = {})
    query = args.fetch(:q) { raise Exception }

    url = URI.escape("#{configuration.base_url}?q=any,contains,#{query}&apikey=#{configuration.apikey}")
    binding.pry

    JSON.parse(open(url).read)

  end

  def build_primo_url(primo_doc)
    "#{configuration.primo_base_web_url}#{primo_doc['pnxId']}&context=L&vid=TULI&search_scope=default_scope&tab=default_tab&lang=en_US"
  end

end
