# frozen_string_literal: true

# Add this mixin to classes that inherit from CatalogController.
module CatalogConfigReinit
  extend ActiveSupport::Concern
  included do
    blacklight_config.configure do |config|
      # Reinitialize blacklight field configurations
      config.search_fields = ActiveSupport::OrderedHash.new
      config.show_fields = ActiveSupport::OrderedHash.new
      config.facet_fields = ActiveSupport::OrderedHash.new
      config.index_fields = ActiveSupport::OrderedHash.new
      config.sort_fields = ActiveSupport::OrderedHash.new
    end
  end
end
