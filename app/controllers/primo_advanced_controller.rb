# frozen_string_literal: true

class PrimoAdvancedController < PrimoCentralController
  copy_blacklight_config_from(PrimoCentralController)

  def advanced_controller?
    true
  end
end
