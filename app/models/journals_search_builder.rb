# frozen_string_literal: true

class JournalsSearchBuilder < SearchBuilder
  self.default_processor_chain += [ :journals_facet ]

  def journals_facet(solr_params)
    if !solr_params["fq"].include? "{!term f=format}Journal/Periodical"
      solr_params["fq"] = solr_params["fq"].push("{!term f=format}Journal/Periodical")
    end
  end
end
