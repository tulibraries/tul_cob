# frozen_string_literal: true

module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  # Override Blacklight core URL Helpers Behavior
  # This override duplicates changes in https://github.com/projectblacklight/blacklight/pull/2071
  # which are not yet released

  # Get the URL for tracking search sessions across pages using polymorphic routing
  def session_tracking_path(document, params = {})
    Rails.logger.debug "Using overriden 'session_tracking_path' method"
    return if document.nil? || !blacklight_config&.track_search_session

    if main_app.respond_to?(controller_tracking_method)
      return main_app.public_send(controller_tracking_method, params.merge(id: document))
    end

    raise "Unable to find #{controller_tracking_method} route helper. " \
    "Did you add `concerns :searchable` routing mixin to your `config/routes.rb`?"
  end
end
