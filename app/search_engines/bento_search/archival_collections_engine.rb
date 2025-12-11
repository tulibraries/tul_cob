# frozen_string_literal: true

module BentoSearch
  class ArchivalCollectionsEngine < BlacklightEngine
    PRIMARY_TYPE_LABELS = {
      "agent_corporate_entity" => "Organization",
      "agent_family"           => "Family",
      "agent_person"           => "Person",
      "archival_object"        => "File",
      "classification"         => "Record Group",
      "resource"               => "Collection"
    }.freeze

    def search_implementation(args)
      query = args.fetch(:query, "")
      service = ArchivesSpaceService.new
      records = service.search(query, types: allowed_types)
      results(records)
    end

    def results(records)
      BentoSearch::Results.new.tap do |bento_results|
        bento_results.total_items = { query_total: records.length }
        records.each { |record| bento_results << conform_to_bento_result(record) }
      end
    end

    def conform_to_bento_result(item)
      primary_type = item["primary_type"].to_s.chomp(".")
      level = item["level"].to_s.chomp(".")
      link = aspace_item_url(item)
      raw = JSON.parse(item["json"])
      title = item_title = raw["title"]
      collection_resolved = raw.dig(
        "instances", 0, "sub_container", "top_container", "_resolved", "collection", 0
      )

      if collection_resolved
        collection_ref = collection_resolved["ref"]
        collection_title = collection_resolved["display_string"]
      else
        collection_ref = nil
        collection_title = nil
      end

      dates_value = item["dates"]
      date =
        case dates_value
        when Array
          first = dates_value.first
          first.is_a?(Hash) ? first["expression"] : first
        when Hash
          dates_value["expression"]
        when String
          dates_value
        else
          nil
        end

      result = BentoSearch::ResultItem.new(
        title: title,
        link: link,
        publication_date: date,
        publisher: " ",
        custom_data: {
          "archival_dates" => date,
          "collection_ref" => collection_ref,
          "collection_title" => collection_title,
          "raw" => item["json"],
          "primary_type_labels" => PRIMARY_TYPE_LABELS[primary_type].to_s.chomp("."),
          "primary_types" => primary_type,
          "level" => level,
        }
      )
    end

    def allowed_types
      %w[
        agent_corporate_entity
        agent_family
        agent_person
        archival_object
        classification
        resource
      ]
    end

    def aspace_item_url(item)
      base_public_url = "https://scrcarchivesspace.temple.edu"
      uri = item["uri"] || ""
      "#{base_public_url}#{uri}"
    end

    def url(helper)
      query = CGI.escape(helper.params[:q].to_s)
      "https://scrcarchivesspace.temple.edu/search?utf8=%E2%9C%93&op%5B%5D=&q%5B%5D=#{query}&limit=&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search"
    end

    def view_link(total = nil, helper)
      full_url = url(helper)
      link_text = Flipflop.style_updates? ? "See all results" : "View all results"
      helper.link_to link_text, full_url, class: "bento-full-results bento_archival_collections_header", target: "_blank"
    end
  end
end
