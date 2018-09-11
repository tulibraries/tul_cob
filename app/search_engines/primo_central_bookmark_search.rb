# frozen_string_literal: true

class PrimoCentralBookmarkSearch < PrimoCentralController
  include Searcher
  include BookmarksConfig

  def fetch(primo_doc_ids)
    # Primo cannot string more than 13 OR queries.
    documents = []

    primo_doc_ids.each_slice(13) do |ids|
      @response, docs = super(ids)
      documents.append(*docs)
      documents.append(*docs_not_found(docs, ids))
    end

    [@response, documents]
  end

  private
    def docs_not_found(docs, ids)
      (ids - docs.map { |doc| doc["pnxId"] })
        .map { |id| PrimoCentralDocument.new("pnxId" => id, "ajax" => true) }
    end
end
