# frozen_string_literal: true

class DocumentDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers

  # General utility methods moved from CatalogHelper
  def library_link_url
    Rails.configuration.library_link
  end

  def formatted_id
    "doc-#{id}"
  end

  # Instance method that needs request URL passed to it
  def redirect_url(request_url)
    Rails.application.routes.url_helpers.new_user_session_path(
      redirect_to: "#{request_url}##{formatted_id}"
    )
  end

  # Static methods that match the original CatalogHelper interface
  def self.doc_id(id)
    "doc-#{id}"
  end

  def self.doc_redirect_url(id, request_url)
    Rails.application.routes.url_helpers.new_user_session_path(
      redirect_to: "#{request_url}#doc-#{id}"
    )
  end

  # Document data processing methods moved from CatalogHelper
  def isbn_data_attribute
    values = fetch(:isbn_display, [])
    values = [values].flatten.map { |value|
      value.gsub(/\D/, "") if value
    }.compact.join(",")

    "data-isbn=#{values}" if !values.empty?
  end

  def oclc_data_attribute
    values = fetch(:oclc_number_display, [])
    values = [values].flatten.map { |value|
      value.gsub(/\D/, "") if value
    }.compact.join(",")

    "data-oclc=#{values}" if !values.empty?
  end

  def lccn_data_attribute
    values = fetch(:lccn_display, []).compact.join(",")

    "data-lccn=#{values}" if !values.empty?
  end

  def default_cover_image
    formats = fetch(:format, [])
    # In case we fetched the default value, or the format value was ""
    formats << "unknown" if formats.empty?
    format = formats.first.to_s.parameterize.underscore

    # Use configuration for format mapping
    format_mapping = Rails.application.config.assets.format_cover_image_mapping
    base_images = Rails.application.config.assets.default_cover_image

    image = base_images
      .merge(format_mapping)
      .fetch(format, "unknown")

    "svg/" + image + ".svg"
  end

  # Safely converts a single or multi-value solr field
  # to a string. Multi values are concatenated with a ', ' by default
  # @param field - the name of a solr field
  # @param joiner - the string to use to concatenate multivalue fields
  def field_joiner(field, joiner = ", ")
    Array.wrap(fetch(field, [])).join(joiner)
  end

  # Formats document formats as HTML spans with CSS classes
  def separate_formats
    formats = %w[]
    fetch(:format, []).each do |format|
      format = ERB::Util.html_escape(format)
      css_class = format.to_s.parameterize.underscore
      formats << "<span class='#{css_class}'> #{format}</span>"
    end
    formats.join("<br />").html_safe
  end

  private

    def new_user_session_path(options = {})
      Rails.application.routes.url_helpers.new_user_session_path(options)
    end
end
