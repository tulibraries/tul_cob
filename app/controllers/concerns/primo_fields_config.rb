# frozen_string_literal: true

# Shared bookmark configuration across bookmarks behaviors.
module PrimoFieldsConfig
  extend ActiveSupport::Concern

  included do
    blacklight_config.configure do |config|
      # Search fields
      config.add_search_field :any, label: "All Fields"
      config.add_search_field :title
      config.add_search_field :creator, label: "Author/Creator"
      config.add_search_field :sub, label: "Subject"
      config.add_search_field(:description, label: "Description") do |field|
        field.include_in_simple_select = false
      end
      config.add_search_field :isbn, label: "ISBN"
      config.add_search_field :issn, label: "ISSN"

      # Index fields
      config.add_index_field :isPartOf, label: "Is Part Of"
      config.add_index_field :creator, label: "Author/Creator", multi: true
      config.add_index_field :type, label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code
      config.add_index_field :date, label: "Year"
      config.add_index_field :availability

      # Facet fields
      config.add_facet_field :tlevel, label: "Article Search Settings", collapse: false, home: true, helper_method: :translate_availability_code
      config.add_facet_field :rtype, label: "Resource Type", limit: true, show: true, home: true, helper_method: :translate_resource_type_code
      config.add_facet_field :creator, label: "Author/Creator"
      config.add_facet_field :topic, label: "Topic"
      config.add_facet_field :lang, label: "Language", limit: true, show: true, helper_method: :translate_language_code

      # Show fields
      # See for refwork tag definitions:
      # https://www.refworks.com/refworks/help/refworks_tagged_format.htm
      config.add_show_field :creator, label: "Author/Creator", helper_method: :browse_creator, multi: true, refwork_tag: :A1
      config.add_show_field :contributor, label: "Contributor", helper_method: :browse_creator, multi: true, refwork_tag: :A2
      config.add_show_field :type, label: "Resource Type", helper_method: :doc_translate_resource_type_code, refwork_tag: :RT
      config.add_show_field :publisher, label: "Published", refwork_tag: :PB
      config.add_show_field :date, label: "Date", refwork_tag: :YR
      config.add_show_field :isPartOf, label: "Is Part of", refwork_tag: :JF
      config.add_show_field :relation, label: "Related Title", helper_method: "list_with_links"
      config.add_show_field :description, label: "Note", helper_method: :tags_strip, refwork_tag: :AB
      config.add_show_field :subject, helper_method: :list_with_links, multi: true, refwork_tag: :K1
      config.add_show_field :isbn, label: "ISBN", refwork_tag: :SN
      config.add_show_field :issn, label: "ISSN", refwork_tag: :SN
      config.add_show_field :lccn, label: "LCCN", refwork_tag: :SN
      config.add_show_field :doi, label: "DOI"
      config.add_show_field :languageId, label: "Language", multi: true, helper_method: :doc_translate_language_code, refwork_tag: :LA

      # Sort fields
      config.add_sort_field :rank, label: "relevance"
      config.add_sort_field :date, label: "date (new to old)"
      config.add_sort_field :author, label: "author/creator (A to Z)"
      config.add_sort_field :title, label: "title (A to Z)"
    end
  end
end
