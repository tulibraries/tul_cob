# frozen_string_literal: true

class BooksSearchBuilder < SearchBuilder
  self.default_processor_chain += [ :books_facet ]

  def books_facet(solr_params)
    if !solr_params["fq"].include? "{!term f=format}Book"
      solr_params["fq"] = solr_params["fq"].push("{!term f=format}Book")
    end
  end
end
