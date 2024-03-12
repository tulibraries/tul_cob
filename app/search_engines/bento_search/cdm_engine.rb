# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, :search_service_class, to: ::SearchController

    def base_url
      "https://digital.library.temple.edu"
    end

    def conform_to_bento_result(item)
      cdm_collection = item.fetch("collection", "").gsub("/", "")
      cdm_id = item.fetch("pointer", "")
      BentoSearch::ResultItem.new(
        title: item.fetch("title", ""),
        publication_date: item.fetch("date", ""),
        source_title: cdm_collection,
        unique_id: cdm_id,
        link: "#{base_url}/digital/collection/#{cdm_collection}/id/#{cdm_id}",
        other_links: [image_scale(cdm_collection, cdm_id)]
      )
    end

    def image_scale(collection, id)
      full_image = "#{base_url}/digital/iiif/2/#{collection}:#{id}/full/,220/0/default.jpg"
      thumb = "#{base_url}/utils/getthumbnail/collection/#{collection}/id/#{id}"
      default_image = "#{base_url}/digital/api/singleitem/image/#{collection}/#{id}"
      the_image = nil

      begin
        if image_available?(full_image)
          the_image = full_image
        end
      rescue OpenURI::HTTPError => e
        Honeybadger.notify("Ran into error while trying to process CDM IIIF image call: #{e.message}")
      end

      if the_image.present?
        the_image
      elsif image_available?(thumb)
        thumb
      else image_available?(default_image)
           default_image
      end
    end

    def search_implementation(args)
      query = args.fetch(:query, "").gsub("/", " ")
      query = ERB::Util.url_encode(query)
      fields = args.fetch(:cdm_fields)
      format = args.fetch(:cdm_format)
      collections = I18n.t("bento.cdm_collections_list")
      cdm_url = "#{base_url}/digital/bl/dmwebservices/index.php?q=dmQuery/#{collections}/CISOSEARCHALL^#{query}^all^and/#{fields}/nosort/5/0/1/0/0/0/0/0/#{format}"
      bento_results = BentoSearch::Results.new
      response = []

      begin
        response = JSON.load(URI.open(cdm_url))
        bento_results.total_items = response.dig("pager", "total") || 0
        response["records"].each do |i|
          unless is_int?(i.fetch("title", ""))
            if bento_results.size < 3
              if image_available?(image_scale(i.fetch("collection", "").gsub("/", ""), i.fetch("pointer", "")))  # only take records with images and with alphanumeric titles
                item = BentoSearch::ResultItem.new
                item = conform_to_bento_result(i)
                bento_results << item
              end
            end
          end
        end
      rescue StandardError => e
        Honeybadger.notify("Error trying to process CDM api response: #{e.message}")
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
  end
end
