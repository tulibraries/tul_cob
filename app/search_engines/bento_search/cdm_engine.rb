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
        publication_date: item.fetch("date"),
        source_title: cdm_collection,
        unique_id: cdm_id,
        link: "https://digital.library.temple.edu/digital/collection/#{cdm_collection}/id/#{cdm_id}",
        other_links: [image_scale(cdm_collection, cdm_id)]
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
      full_image = "https://digital.library.temple.edu/utils/ajaxhelper/?CISOROOT=#{collection}&CISOPTR=#{id}&action=2&DMSCALE=#{image_scale}&DMHEIGHT=340"
      thumb = "https://digital.library.temple.edu/utils/getthumbnail/collection/#{collection}/id/#{id}"
      default_image = "https://digital.library.temple.edu/digital/collection/#{collection}/id/#{id}"

      if image_available?(full_image)
        full_image
      elsif image_available?(thumb)
        thumb
      else image_available?(default_image)
           default_image
      end
    end

    def search_implementation(args)
      query = args.fetch(:query, "").gsub("/", " ")
      bento_results = BentoSearch::Results.new
      query = ERB::Util.url_encode(query)
      fields = args.fetch(:cdm_fields)
      format = args.fetch(:cdm_format)
      cdm_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmQuery/all/CISOSEARCHALL^#{query}^all^and/#{fields}/nosort/35/0/1/#{format}"
      response = []

      begin
        response = JSON.load(URI.open(cdm_url))
        bento_results.total_items = response.dig("pager", "total") || 0
        response["records"].each do |i|
          unless (["/p245801coll10", "/p15037coll12"].include? i.fetch("collection")) || is_int?(i["title"])
            if bento_results.size < 3
              if image_available?(image_scale(i["collection"].gsub("/", ""), i["pointer"]))  # only take records with images and with alphanumeric titles
                item = BentoSearch::ResultItem.new
                item = conform_to_bento_result(i)
                bento_results << item
              end
            end
          end
        end
      rescue StandardError => e
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
