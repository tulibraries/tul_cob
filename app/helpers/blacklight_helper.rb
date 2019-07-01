# frozen_string_literal: true

module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  ##
  # Overrides same method in Blacklight::BlacklightHelperBehavior.
  #
  # Makes index_presenter the default presenter.
  #
  # TODO: remove if when following PR gets merged.
  # https://github.com/projectblacklight/blacklight/pull/2117
  def presenter(document)
    case action_name
    when "show", "citation"
      show_presenter(document)
    else
      index_presenter(document)
    end
  end
end
