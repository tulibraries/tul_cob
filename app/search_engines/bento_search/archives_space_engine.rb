# frozen_string_literal: true

module BentoSearch
  class ArchivesSpaceEngine < BlacklightEngine
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
        records.each { |record| bento_results << conform_to_bento_result(record) }
      end
    end

    def conform_to_bento_result(record)
      primary_type = record["primary_type"]
      title = record["title"] || record["display_string"] || "(untitled)"
      link = aspace_record_url(record)

      dates_value = record["dates"]
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

      collection_value = record["collection"]
      collection_title =
        case collection_value
        when Hash
          collection_value["display_string"]
        when String
          collection_value
        else
          nil
        end

      collection_uri =
        case collection_value
        when Hash
          collection_value["ref"]
        else
          nil
        end

      BentoSearch::ResultItem.new(
        title: title,
        link: link,
        custom_data: {
          primary_type: primary_type,
          type_label: PRIMARY_TYPE_LABELS[primary_type],
          date: date,
          collection_title: collection_title,
          collection_uri: collection_uri,
        }.compact
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

    def aspace_record_url(record)
      base_public_url = "https://scrcarchivesspace.temple.edu"
      uri = record["uri"] || ""
      "#{base_public_url}#{uri}"
    end
  end
end
