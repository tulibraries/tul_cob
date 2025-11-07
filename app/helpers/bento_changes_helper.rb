# frozen_string_literal: true

module BentoChangesHelper
  def aspace_integration_enabled?
    Flipflop.aspace_integration?
  end

  def style_updates_enabled?
    Flipflop.style_updates?
  end
end
