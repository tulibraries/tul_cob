# frozen_string_literal: true

module QueryListable
  extend ActiveSupport::Concern

  def query_list_footer_value(field)
    if self[field]&.include?(0)
      self[field].delete(0)
    end

    value = self[field]&.first

    case field
    when "date_added_facet"
      begin
        Date.parse("#{value}").strftime("%Y-%m-%d")
      rescue => e
        Honeybadger.notify("Error trying to parse date_added_facet value; @htomren " + "#{e.message}")
        ""
      end
    else
      value
    end
  end
end
