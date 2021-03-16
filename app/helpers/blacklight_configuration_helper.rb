# frozen_string_literal: true

module BlacklightConfigurationHelper
  include Blacklight::ConfigurationHelperBehavior

  ##
  # Overrides Blacklight::ConfigurationHelperBehavior.index_fields.
  #
  # We need this override in order to short circuit the call to
  # blacklight_config in order to switch out the configuration for a specfic
  # document type.
  #
  # Index fields to display for a type of document
  #
  # @param [SolrDocument] document
  # @return [Array<Blacklight::Configuration::Field>]
  def index_fields(document = nil)
    @blacklight_config&.index_fields || blacklight_config.index_fields
  end

  def facet_field_label(field)
    field = "lc_facet" if field == "lc_classification"
    if parent_config = blacklight_config.facet_fields.find { |k, v| v.pivot && v.pivot.include?(field) }
      parent_config[1].display_label("facet")
    else
      super field
    end
  end
end
