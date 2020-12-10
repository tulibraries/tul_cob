# frozen_string_literal: true

module BookmarkHelper
  def index_controller(document = {}, count = 0)
    if (document.ajax? rescue false)
      "data-controller=#{document.ajax_controller} data-index-url=#{document.ajax_url(count)}"
    end
  end
end
