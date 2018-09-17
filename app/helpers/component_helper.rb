# frozen_string_literal: true

module ComponentHelper
  include Blacklight::ComponentHelperBehavior

  # Overrides Blacklight::ComponentHelperBehavior.render_show_doc_actions
  # in order to skip sms action for non book items.
  #
  # Render "document actions" for the item detail 'show' view.
  # (this normally renders next to title)
  #
  # By default includes 'Bookmarks'
  #
  # @param [SolrDocument] document
  # @param [Hash] options
  # @return [String]
  def render_show_doc_actions(document = @document, options = {}, &block)
    if !document&.fetch(:format, nil)&.include? "Book"
      blacklight_config.show.document_actions.delete(:sms)
    end

    render_filtered_partials(blacklight_config.show.document_actions, { document: document }.merge(options), &block)
  end
end
