# frozen_string_literal: true

class IndexPresenter < Blacklight::IndexPresenter
  def fields_to_render
    return super unless block_given?
    super do |field_name, field_config, field_presenter|
      yield field_name, field_config, field_presenter unless field_name == "lc_call_number_display"
    end
  end

  def lc_call_number_field_to_render
    return unless fields["lc_call_number_display"] && block_given?
    field_presenter = field_presenter(fields["lc_call_number_display"])
    yield "lc_call_number_display", fields["lc_call_number_display"], field_presenter if field_presenter.render_field?
  end

  def each_summary_field
    fields_to_render do |field_name, field_config, field_presenter|
      field_presenter.except_operations << Blacklight::Rendering::Join
      yield field_name, field_config, field_presenter if field_config[:type] == :summary
    end
  end
end
