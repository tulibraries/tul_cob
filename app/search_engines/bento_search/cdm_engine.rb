# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, :search_service_class, to: ::SearchController

    def base_url
      "https://digital.library.temple.edu"
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
      end
    end

    def cdm_collections_api_response
      collections_url = "#{base_url}/digital/bl/dmwebservices/index.php?q=dmGetCollectionList/json"
      begin
        JSON.load(URI.open(collections_url))
      rescue StandardError => e
        Honeybadger.notify("Error trying to process CDM Collections api response: #{e.message}")
      end
    end

    def image_scale(collection, id)
      full_image = "#{base_url}/digital/iiif/2/#{collection}:#{id}/full/,220/0/default.jpg"
      thumbnail_image = "#{base_url}/utils/getthumbnail/collection/#{collection}/id/#{id}"
      default_image = "#{base_url}/digital/api/singleitem/image/#{collection}/#{id}"
      the_image = nil

      begin
        if image_available?(full_image)
          the_image = full_image
        end
      rescue OpenURI::HTTPError => e
        # Honeybadger.notify("Ran into error while trying to process CDM IIIF image call: #{e.message}")
      end

      if the_image.present?
        the_image
      elsif image_available?(thumbnail_image)
        thumbnail_image
      else image_available?(default_image)
           default_image
      end
    end

    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      response = []
      response = cdm_api_response(args)

      if response["records"].present?
        bento_results.total_items = response.dig("pager", "total") || 0
        collections = []
        collections = cdm_collections_api_response

        response["records"].each do |i|
          collection_id = i.fetch("collection", "").gsub("/", "")
          cdm_id = i.fetch("pointer", "")

          # only take records with images and with alphanumeric titles
          unless is_int?(i.fetch("title", ""))
            if bento_results.size < 3
              cdm_image = image_scale(collection_id, cdm_id)
              if cdm_image.present?
                item = BentoSearch::ResultItem.new(
                  title: i.fetch("title", ""),
                  publication_date: i.fetch("date", ""),
                  source_title: cdm_collection_name(collection_id, collections),
                  unique_id: cdm_id,
                  link: "#{base_url}/digital/collection/#{collection_id}/id/#{cdm_id}",
                  other_links: [cdm_image]
                )
                bento_results << item
              end
            end
          end
        end
      end
      bento_results
    end

    def is_int?(str)
      !!(str =~ /\A[-+]?[0-9]+\z/)
    end

    def image_available?(link)
      res = URI.open(link)
      res.size > 0
    end

    def cdm_collection_name(collection_id, collections_response)
      collection = collections_response.select { |collection| collection["secondary_alias"] if collection["secondary_alias"] == collection_id } 
      collection.first["name"] unless collection.blank?
    end
  end
end
