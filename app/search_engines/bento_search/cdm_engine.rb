# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, :search_service_class, to: ::SearchController

    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      response = cdm_api_response(args)
      bento_results.total_items = response.dig("pager", "total") || 0
      collections = cdm_collections_api_response


      # use only records that have alphanumeric titles.
      records = response["records"].select { |record| !is_int?(record["title"].to_s) }

      records = records.map { |record|
        collection_id = record.fetch("collection", "").gsub("/", "")
        cdm_id = record.fetch("pointer", "")

        {
          title: record.fetch("title", ""),
          publication_date: record.fetch("date", ""),
          source_title: cdm_collection_name(collection_id, collections),
          unique_id: cdm_id,
          link: "#{base_url}/digital/collection/#{collection_id}/id/#{cdm_id}",
          image_link_thread: Thread.new { get_image_link(collection_id, cdm_id) },
          other_links: [],
        }
      }

      # reduce records to the first 3 that have images.
      records.reduce(bento_results) { |acc, record|

        if acc.count == 3
          break acc
        end

        image_link = record[:image_link_thread].value

        if image_link.present?
          record[:other_links] << image_link
          acc << BentoSearch::ResultItem.new(record.except(:image_link_thread))
        end

        acc
      }
    end

    def cdm_api_response(args)
      query = args.fetch(:query, "").gsub("/", " ")
      query = ERB::Util.url_encode(query)
      cdm_fields = "title!date"
      cdm_format = "json"
      cdm_collections_ids = I18n.t("bento.cdm_collections_list")
      cdm_url = "#{base_url}/digital/bl/dmwebservices/index.php?q=dmQuery/#{cdm_collections_ids}/CISOSEARCHALL^#{query}^all^and/#{cdm_fields}/nosort/5/0/1/0/0/0/0/0/#{cdm_format}"
      begin
        JSON.load(URI.open(cdm_url))
      rescue StandardError => e
        Honeybadger.notify("Error trying to process CDM api response: #{e.message}")
        { records: [], pager: { total: 0 } }.with_indifferent_access
      end
    end

    def cdm_collections_api_response
      collections_url = "#{base_url}/digital/bl/dmwebservices/index.php?q=dmGetCollectionList/json"
      begin
        Rails.cache.fetch(:cdm_api_response, expires_in: 1.day) { JSON.load(URI.open(collections_url))  }
      rescue StandardError => e
        Honeybadger.notify("Error trying to process CDM Collections api response: #{e.message}")
        []
      end
    end

    def get_image_link(collection, id)
      full_image_url = "#{base_url}/digital/iiif/2/#{collection}:#{id}/full/,220/0/default.jpg"
      thumbnail_image_url = "#{base_url}/utils/getthumbnail/collection/#{collection}/id/#{id}"

      if image_available?(full_image_url)
        full_image_url
      elsif image_available?(thumbnail_image_url)
        thumbnail_image_url
      else
        ""
      end
    end

    def base_url
      "https://digital.library.temple.edu"
    end


    def is_int?(str)
      !!(str =~ /\A[-+]?[0-9]+\z/)
    end

    def image_available?(link)
      begin
        url = URI::parse(link)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        http.open_timeout = 5
        http.read_timeout = 5

        response = http.head(url.request_uri)
        response.code.to_i == 200
      rescue => e
        false
      end
    end

    def cdm_collection_name(collection_id, collections_response)
      collection = collections_response.select { |collection| collection["secondary_alias"] if collection["secondary_alias"] == collection_id }
      collection.first["name"] unless collection.blank?
    end
  end
end
