# frozen_string_literal: true

class PrimoSearchService < Blacklight::SearchService
  def fetch(primo_doc_ids)
    # Primo cannot string more than 10 OR queries.
    documents = []

    primo_doc_ids
      .map { |id| id.gsub(/^TN_/, "") }
      .each_slice(10) do |ids|
      @response, docs = super(ids)
      documents.append(*docs)
      documents.append(*docs_not_found(docs, ids))
    end

    @response["response"]["numFound"] = documents.count
    @response["response"]["docs"] = documents

    [@response, documents]
  end

  private
    def docs_not_found(docs, ids)
      if docs.length == ids.length
        []
      else
        (ids - docs.map { |doc| doc["pnxId"] })
          .map { |id| PrimoCentralDocument.new("pnxId" => id, "ajax" => true) }
      end
    end
end
