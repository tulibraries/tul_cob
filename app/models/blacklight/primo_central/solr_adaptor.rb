# frozen_string_literal: true

module Blacklight::PrimoCentral
  module SolrAdaptor
    def solr_to_primo_facet(field)
      solr_to_primo_facets[field] || field
    end

    def solr_to_primo(field)
      solr_to_primo_keys[field] || field
    end

    def primo_to_solr_facet(field)
      primo_to_solr_facets[field] || field
    end

    def primo_to_solr(field)
      primo_to_solr_keys[field] || field
    end

    def solr_to_primo_facets
      SOLR_TO_PRIMO_FACETS
    end

    def solr_to_primo_keys
      SOLR_TO_PRIMO_KEYS
    end

    def primo_to_solr_facets
      solr_to_primo_facets.invert
    end

    def primo_to_solr_keys
      solr_to_primo_keys.invert
    end

    def primo_to_solr_search(field)
      (PrimoCentralController.blacklight_config.search_fields.dig(field, "catalog_map") || field).to_s
    end

    private

      SOLR_TO_PRIMO_FACETS = {}

      SOLR_TO_PRIMO_KEYS = {
        "title_with_subtitle_display" => "title",
        "title_with_subtitle_truncated_display" => "title",
        "title_statement_display" => "title",
        "title_truncated_display" => "title",
        "creator_display" => "creator",
        "imprint_display" => "publisher",
        "contributor_display" => "contributor",
        "pub_date_display" => "creationdate",
        "pub_date" => "creationdate",
        "note_display" => "description",
        "subject_display" => "subject",
        "isbn_display" => "isbn",
        "issn_display" => "issn",
        "lccn_display" => "lccn",
        "language_display" => "languageId",
      }
  end
end
