# frozen_string_literal: true

class SolrDatabaseDocument < SolrDocument
  use_extension(Blacklight::Document::Email)
  use_extension(Blacklight::Document::Sms)


  # Databases do not have any alma availability to report
  def alma_availability_mms_ids
    []
  end
end
