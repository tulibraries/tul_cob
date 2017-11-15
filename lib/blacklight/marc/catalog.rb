# frozen_string_literal: true

module Blacklight::Marc
  module Catalog
    # Overrides Blacklight::Marc::Catalog::librarian_view in order to correctly use marc_view data.
    def librarian_view
      @response, @document = fetch params[:id]
      if @document["marc_display_raw"]
        marc_display_raw = []
        # Pretty print the XML
        doc = REXML::Document.new(@document["marc_display_raw"])
        formatter = REXML::Formatters::Pretty.new
        formatter.compact = true
        formatter.write(doc, marc_display_raw)

        @marc_view = [ marc_display_raw.to_s ]
      else
        @marc_view = [ t("blacklight.search.librarian_view.empty") ]
      end

      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end
  end
end
