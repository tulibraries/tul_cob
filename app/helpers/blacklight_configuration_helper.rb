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
end
