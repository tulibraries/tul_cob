# frozen_string_literal: true

class TulDecorator < BentoSearch::StandardDecorator
  # This is an override of BentoSearch::StandardDecorator::render_source_info.
  # It's required becase we need to add a label to the publisher field.
  def render_source_info
    parts = []

    if self.source_title.present?
      parts << _h.content_tag("span", self.source_title, class: "source_title")
    elsif self.publisher.present?
      parts << _h.content_tag("span", self.publisher, class: "publisher")
    end

    if text = self.render_citation_details
    end

    return _h.safe_join(parts, "")
  end

  def render_authors_list
    parts = []

    first_three = self.authors.slice(0,3)

    first_three.each_with_index do |author, index|
      parts << _h.content_tag("span", :class => "author") do
        self.author_display(author)
      end
      if (index + 1) < first_three.length
        parts << "; "
      end
    end

    if self.authors.length > 3
      parts << I18n.t("bento_search.authors_et_al")
    end

    return _h.safe_join(parts, "")
  end
end
