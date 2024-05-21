# frozen_string_literal: true

class TulThumbnailComponent < Blacklight::Document::ThumbnailComponent
  include CatalogHelper

  def initialize(presenter: nil, document: nil, counter:, image_options: {}, gb_preview: nil)
    @presenter = presenter
    @document = presenter&.document || document
    @image_options = { alt: "" }.merge(image_options)
    @gb_preview = gb_preview
  end

  def render_google_books_data_attribute
    isbn_data_attribute(@document) || lccn_data_attribute(@document) || oclc_data_attribute(@document)
  end

  def before_render
    @cover = render_google_books_data_attribute
  end

  def render_gb_preview?
    !@gb_preview.nil?
  end

  def render?
    true
  end
end
