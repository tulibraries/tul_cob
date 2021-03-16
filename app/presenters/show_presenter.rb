# frozen_string_literal: true

class ShowPresenter < Blacklight::ShowPresenter
  def each_primary_field
    fields_to_render do |field_name, field_config, field_presenter|
      field_presenter.except_operations << Blacklight::Rendering::Join
      yield field_name, field_config, field_presenter if field_config[:type] == :primary
    end
  end

  def each_secondary_field
    fields_to_render.each do |field_name, field_config, field_presenter|
      field_presenter.except_operations << Blacklight::Rendering::Join
      yield field_name, field_config, field_presenter unless field_config[:type] == :primary
    end
  end

  def render_field?(field_config)
    field_presenter(field_config).render_field? and has_value? field_config
  end
end
