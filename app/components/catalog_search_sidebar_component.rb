# frozen_string_literal: true

class CatalogSearchSidebarComponent < Blacklight::Search::SidebarComponent
  def initialize(blacklight_config:, response:, view_config:, params: nil)
    super(blacklight_config:, response:, view_config:)
    @tweak_params = params
  end

  private

  attr_reader :tweak_params

  def tweak_component
    TweakQueryComponent.new(blacklight_config: @blacklight_config, params: tweak_params || helpers.params)
  end
end
