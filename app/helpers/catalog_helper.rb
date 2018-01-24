# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include BlacklightAlma::CatalogOverride

  def thumbnail_classes(document)
    classes = %w[thumbnail col-sm-3 col-lg-2]
    document[:format].each do |format|
      classes << "#{format.parameterize.downcase.underscore}_format"
    end
    classes.join " "
  end

  def isbn_data_attribute(document)
    value = document.fetch(:isbn_display, "")
    return value if value.empty?
    # Get the first ISBN and strip non-numerics
    "data-isbn=#{value.first.gsub(/\D/, '')}"
  end

  def lccn_data_attribute(document)
    value = document.fetch(:lccn_display, "")
    return value if value.empty?
    # Get the first ISSN and strip non-numerics
    "data-lccn=#{value.first.gsub(/\D/, '')}"
  end

  def default_cover_image(document)
    "svg/"+document.fetch(:format, "unknown")[0].to_s.parameterize.underscore+".svg"
  end

  def separate_formats(document)
    document[:format].each do |format|
      "<span class='"+document.fetch(:format, "unknown")[0].to_s.parameterize.underscore+"'>"+document.fetch(:format, "unknown")[0].to_s+"</span>"
    end
  end
end
