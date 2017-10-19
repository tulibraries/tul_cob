# frozen_string_literal: true

class TulDecorator < BentoSearch::StandardDecorator
  # This is an override of BentoSearch::StandardDecorator::render_source_info.
  # It's required becase we need to add a label to the publisher field.
  def render_source_info
    parts = []

    if self.source_title.present?
      parts << _h.content_tag("span", I18n.t("bento_search.published_in"), class: "source_label")
      parts << _h.content_tag("span", self.source_title, class: "source_title")
      parts << ". "
    elsif self.publisher.present?
      publisher = I18n.t("bento_search.published") + ": "
      parts << _h.content_tag("span", publisher, class: "source_label")
      parts << _h.content_tag("span", self.publisher, class: "publisher")
      parts << ". "
    end

    if text = self.render_citation_details
      parts << text << "."
    end

    return _h.safe_join(parts, "")
  end
end
