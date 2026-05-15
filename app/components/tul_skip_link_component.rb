# frozen_string_literal: true

class TulSkipLinkComponent < Blacklight::SkipLinkComponent
  def link_to_search
    return if helpers.advanced_search_page?

    render skip_link_item_component.new(text: t("blacklight.skip_links.search_field"), href: search_id)
  end

  def link_to_filters
    return if helpers.advanced_search_page? || search_index_page?

    render skip_link_item_component.new(text: t("blacklight.skip_to_filters_link"), href: "#search_field")
  end

  def search_id
    "#q"
  end

  private

    def search_index_page?
      helpers.controller_name == "search" && helpers.action_name == "index"
    end
end
