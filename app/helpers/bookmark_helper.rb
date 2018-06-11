# frozen_string_literal: true

module BookmarkHelper
  def toggle_document_context(document = nil)
    # Only toggle the lookup_context for Bookmark items.
    if @_controller.class == BookmarksController
      blacklight_reconfig(document)
      reset_lookup_context(document)
    end
  end

  def blacklight_reconfig(document = nil)
    type = document&.class&.to_s || :default
    @document_config_map ||= {}
    @document_config_map[:default] ||= blacklight_config.deep_copy
    @document_config_map["SolrDocument"] ||= CatalogController.blacklight_config.deep_copy
    @document_config_map["PrimoCentralDocument"] ||= PrimoCentralController.blacklight_config.deep_copy
    @blacklight_config = @document_config_map[type]
  end

  def reset_lookup_context(document = nil)
    type = document&.class&.to_s || :default
    lookup_context.prefixes = document_controller_map.fetch(type, :default)
      .constantize.new.lookup_context.prefixes
  end

  def document_controller_map
    {
      "SolrDocument" => "CatalogController",
      "PrimoCentralDocument" => "PrimoCentralController",
      :default => "BookmarksController"
    }
  end
end
