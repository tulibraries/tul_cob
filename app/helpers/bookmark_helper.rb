# frozen_string_literal: true

module BookmarkHelper
  def index_controller(document = {}, count = 0)
    if (document.ajax? rescue false)
      "data-controller=#{document.ajax_controller} data-index-url=#{document.ajax_url(count)}"
    end
  end

  def current_entries_info(collection, options = {})
    end_num =
      if collection.respond_to?(:groups) && render_grouped_response?(collection)
        collection.groups.length
      else
        collection.limit_value
      end

    end_num =
      if collection.offset_value + end_num <= collection.total_count
        collection.offset_value + end_num
      else
        collection.total_count
      end

    begin_num =
      if collection.total_count == 0
        0
      else
        collection.offset_value + 1
      end
    "#{begin_num} - #{end_num}"
  end
end
