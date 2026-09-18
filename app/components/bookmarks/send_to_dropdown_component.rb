# frozen_string_literal: true

module Bookmarks
  class SendToDropdownComponent < ViewComponent::Base
    def initialize(documents:, url_opts: {})
      @documents = documents
      @url_opts = Blacklight::Parameters.sanitize(url_opts.with_indifferent_access.except(:format, :commit, :utf8, :controller, :action)).merge(format: :html)
    end

    def actions
      @actions ||= helpers.document_actions(@documents, options: { document: nil })
    end

    def before_render
      @ris_href = helpers.ris_path
    end

    def action_label(action)
      t("blacklight.tools.#{action.name}", default: action.label || action.name.to_s.humanize)
    end

    attr_reader :ris_href
  end
end
