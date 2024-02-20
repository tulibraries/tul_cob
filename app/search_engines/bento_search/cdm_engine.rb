# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, :search_service_class, to: ::SearchController

    def conform_to_bento_result(item)
      cdm_collection = item.fetch("collection", "").gsub("/", "")
      cdm_id = item.fetch("pointer")
      BentoSearch::ResultItem.new(
        title: item.fetch("title"),
        cdm_date: item.fetch("date"),
        cdm_collection: cdm_collection,
        cdm_id: cdm_id,
        cdm_record_link: "https://digital.library.temple.edu/digital/collection/#{cdm_collection}/id/#{cdm_id}",
        cdm_thumbnail_link: image_scale(cdm_collection, cdm_id)
      )
    end

    def image_scale(collection, id)
      begin
        image_info = JSON.load(URI.open("https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmGetImageInfo/#{collection}/#{id}/json"))
        image_width = image_info["width"]
        image_scale = (image_width <= 2500) ? 50 : 6  #this may take some fine tuning depending on all available sizes
      rescue StandardError => e
        Honeybadger.notify("Ran into error while try to process CDM image info api call: #{e.message}")
      end
      "https://digital.library.temple.edu/utils/ajaxhelper/?CISOROOT=#{collection}&CISOPTR=#{id}&action=2&DMSCALE=#{image_scale}&DMHEIGHT=340"
    end

    def search_implementation(args)
      query = args.fetch(:query, "").gsub("/", " ")
      bento_results = BentoSearch::Results.new
      query = ERB::Util.url_encode(query)
      fields = args.fetch(:cdm_fields)
      format = args.fetch(:cdm_format)
      cdm_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmQuery/all/CISOSEARCHALL^#{query}^all^and/#{fields}/sortby/9/#{format}"
      response = []

      begin
        response = JSON.load(URI.open(cdm_url))
        total_items = response.dig("pager", "total") || 0
        response["records"].each do |i|
          item = BentoSearch::ResultItem.new
          item = conform_to_bento_result(i)
          if (bento_results.size < 3) && (image_available?(item.cdm_thumbnail_link))
            bento_results << item unless is_int?(item.title)
          end
        end
      rescue StandardError => e
        bento_results.total_items = 0
        Honeybadger.notify("Ran into error while try to process CDM: #{e.message}")
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
