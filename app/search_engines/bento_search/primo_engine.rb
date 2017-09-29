require 'open-uri'

class BentoSearch::PrimoEngine
  include BentoSearch::SearchEngine

  def search_implementation(args)

    query = args.fetch(:query, "")
    primo_results = search_primo({q: query})

    results = BentoSearch::Results.new
    primo_results['docs'].each do |doc|
      results << conform_to_bento_result(doc)
    end

    results
  end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new({
        title: item.fetch("title", ""),
        authors: item.fetch("contributor", []).map { |creator| BentoSearch::Author.new({display: creator})},
        link: build_primo_url(item)
        })
    end

  def search_primo(args = {})
    query = args.fetch(:q, "")
    url = URI.escape("#{configuration.base_url}?q=any,contains,#{query}&apikey=#{configuration.apikey}")
    JSON.parse(open(url).read)
  end

  def build_primo_url(primo_doc)
    "#{configuration.primo_base_web_url}#{primo_doc['pnxId']}&context=L&vid=TULI&search_scope=default_scope&tab=default_tab&lang=en_US"
  end

end
