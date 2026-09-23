# frozen_string_literal: true

module LibrarySearch
  class ShowToolsComponent < Blacklight::Component
    def initialize(document:)
      @document = document
    end

    def render?
      actions.any? || citation_action?
    end

    def bookmark_action
      @bookmark_action ||= actions.find { |action| action.key == :bookmark }
    end

    def send_to_actions
      @send_to_actions ||= actions.reject { |action| action.key == :bookmark }
    end

    def render_action(action, link_classes: "nav-link")
      component = action.component || Blacklight::Document::ActionComponent
      rendered_action = helpers.render(component.new(action: action,
                                                     document: document,
                                                     link_classes: link_classes,
                                                     options: {},
                                                     url_opts: {}))

      helpers.render_show_tool_dropdown_item(action.key, rendered_action)
    end

    def error_link
      helpers.link_to helpers.t("blacklight.tools.error_html"),
                      helpers.build_error_libwizard_url(document),
                      target: "_blank",
                      id: "errorLink",
                      class: "btn"
    end

    def citation_action?
      Flipflop.citeproc_citations? && document.citable?
    end

    def citation_link
      helpers.link_to helpers.t("blacklight.tools.cite_html", current_range: ""),
                      helpers.citation_solr_document_path(id: document.id),
                      id: "citeLink",
                      class: "btn",
                      data: { blacklight_modal: "trigger" }
    end

    private

      attr_reader :document

      def actions
        @actions ||= helpers.document_actions(document)
      end
  end
end
