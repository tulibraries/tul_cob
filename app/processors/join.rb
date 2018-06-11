# frozen_string_literal: true

# Joins values using configured value or linebreak
class CustomJoin < Blacklight::Rendering::AbstractStep
  include ActionView::Helpers::TextHelper

  def render
    joiner = config.join_with || "h<br>".html_safe
    next_step(safe_join(values, joiner))
  end
end
