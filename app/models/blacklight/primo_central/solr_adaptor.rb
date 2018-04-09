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

    private

      SOLR_TO_PRIMO_FACETS = {
        "creator_facet" => "creator",
        "availability_facet" => "tlevel",
        "format" => "rtype",
        #"pub_date_sort" => "creationdate",
        "subject_topic_facet" => "topic",
        "language_facet" => "lang",
      }

      SOLR_TO_PRIMO_KEYS = {
        "title_statement_display" => "title",
        "creator_display" => "creator",
        "imprint_display" => "publisher",
        "contributor_display" => "contributor",
        "phys_desc_display" => "format",
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
