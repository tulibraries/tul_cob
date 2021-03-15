# frozen_string_literal: true

class BooksSearchBuilder < SearchBuilder
  self.default_processor_chain += [ :no_journals ]


  def no_journals(solr_parameters)
    if solr_parameters["fq"].blank?
      solr_parameters["fq"] = ["!format:Journal/Periodical"]
    else
      solr_parameters["fq"] += ["!format:Journal/Periodical"]
    end
  end
end
