# frozen_string_literal: true

class SolrDatabaseDocument < SolrDocument
  use_extension(LibrarySearch::Document::Email)

  # Databases do not have any alma availability to report
  def alma_availability_mms_ids
    []
  end
end
