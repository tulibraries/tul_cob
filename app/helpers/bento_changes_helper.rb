# frozen_string_literal: true

module BentoChangesHelper
  def aspace_integration.enabled?
    Flipflop.aspace_integration?
  end

  def style_updates.enabled?
    Flipflop.style_updates?
  end
end
