# frozen_string_literal: true

class TulThumbnailComponent < Blacklight::Document::ThumbnailComponent
  include CatalogHelper

  def initialize(presenter:, image_options: {}, gb_preview: nil)
    @presenter = presenter
    @document = presenter&.document
    @decorated_doc = @document ? DocumentDecorator.new(@document) : nil
    @image_options = { alt: "" }.merge(image_options)
    @gb_preview = gb_preview
  end

  def render_google_books_data_attribute
    return nil unless @decorated_doc
    @decorated_doc.isbn_data_attribute || @decorated_doc.lccn_data_attribute || @decorated_doc.oclc_data_attribute
  end

  def before_render
    @cover = render_google_books_data_attribute
  end

  def render_gb_preview?
    !@gb_preview.nil?
  end

  def render?
    @document.present?
  end
end
