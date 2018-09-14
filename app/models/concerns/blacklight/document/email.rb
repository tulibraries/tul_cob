# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Email
  # Return a text string that will be the body of the email
  # Overridden in order to add our own custom fields to email text.
  def to_email_text
    body = []
    add_bibliographic_fields(body)
    add_holdings_fields(body)
    body.join("\n") unless body.empty?
  end

  private

    def add_single_valued_field(body, i18_label, value)
      body << I18n.t(i18_label, value: value) if value.present?
    end

    def add_multi_valued_field(body, i18_label, value)
      value.each { |v| add_single_valued_field(body, i18_label, v.gsub("|", " ")) } if value.present?
    end

    def add_holding_field(body, i18_label, value)
      value.each { |v| add_single_valued_field(body, i18_label, v) } if value.present?
    end

    def add_bibliographic_fields(body)
      add_single_valued_field(body, "blacklight.email.text.title", self["title_statement_display"].first)
      add_multi_valued_field(body, "blacklight.email.text.creator", self["creator_display"])
      add_multi_valued_field(body, "blacklight.email.text.contributor", self["contributor_display"])
      add_multi_valued_field(body, "blacklight.email.text.imprint", self["imprint_display"])
      add_multi_valued_field(body, "blacklight.email.text.isbn", self["isbn_display"])
      add_multi_valued_field(body, "blacklight.email.text.issn", self["issn_display"])
      add_multi_valued_field(body, "blacklight.email.text.alma_mms", self["alma_mms_display"])
    end

    def add_holdings_fields(body)
      alma_response = HTTParty.get("https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/ALL/items?apikey=#{apikey}")
      total_records = alma_response["items"]["total_record_count"]
      unless total_records == "0"
        if total_records == "1"
          add_holding_field(body, "blacklight.email.text.holdings", [alma_response.dig("items", "item", "item_data", "library", "desc") + " " + alma_response.dig("items", "item", "item_data", "location", "desc") + " " + alma_response.dig("items", "item", "holding_data", "call_number")])
        else
          add_holding_field(body, "blacklight.email.text.holdings", alma_response["items"]["item"].map { |k, v| k.dig("item_data", "library", "desc") + " " + k.dig("item_data", "location", "desc") + " " + k.dig("holding_data", "call_number") })
        end
      end
    end

    def mms_id
      self["alma_mms_display"].first
    end

    def apikey
      Alma.configuration.apikey
    end
end
