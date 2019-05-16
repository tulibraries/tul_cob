# frozen_string_literal: true

# Shared bookmark configuration across bookmarks behaviors.
module BookmarksConfig
  extend ActiveSupport::Concern

  included do
    blacklight_config.configure do |config|
      # Sorting is difficult when merging multiple sources.
      config.sort_fields = ActiveSupport::OrderedHash.new

      # Disable the per_page configuration
      config.per_page = []
      config.default_per_page = 1000

      config.add_show_tools_partial(:citation)
      # Need to add citation for side effect only.
      config.show.document_actions.delete(:citation)

      # Tracking bookmarks causes routing error (BL-903)
      config.track_search_session = false
    end
  end
end
