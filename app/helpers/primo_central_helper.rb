# frozen_string_literal: true

module PrimoCentralHelper
  def translate_code(code, type)
    t("#{type}_code.#{code}", default: code)
  end

  def translate_language_code(code)
    translate_code(code, "language")
  end

  def translate_availability_code(code)
    translate_code(code, "availability")
  end

  def translate_resource_type_code(code)
    translate_code(code, "resource_type")
  end

  def doc_translate_language_code(presenter)
    codes = presenter[:document][:languageId] || []
    codes.map { |c| translate_code(c, "language") }
  end

  def doc_translate_resource_type_code(presenter)
    codes = presenter[:document][:type]
    codes&.map { |c| translate_code(c, "resource_type") }
  end

  def index_translate_resource_type_code(presenter)
    codes = doc_translate_resource_type_code(presenter)
    if codes
      presenter[:document][:format] = codes
    end
    separate_formats(presenter)
  end

  # Returns a list of partials to render in the availability section
  def availability_link_partials
    partials = []
    if @document.has_direct_link?
      partials.push("direct_link")
    else
      partials.push("online")
    end
    partials
  end

  def index_buttons_partials
    availability_link_partials.map { |p| "#{p}_button" }
  end

  def bento_availability(item)
    if item.has_direct_link?
      link_to "Online", single_link_builder(bento_link(item)), class: "btn btn-sm bento-avail-btn", title: "This link opens the resource in a new tab.", target: "_blank"
    else
      link_to "Online", primo_central_document_url(item), class: "btn btn-sm bento-avail-btn"
    end
  end

  def document_link
    @document["link"]
  end

  def bento_link(item)
    item["link"]
  end

  def document_link_label
    @document["link_label"]
  end

  def document_id
    # This just needs to be unique.
    # Hashing because () characters mess with javacript.
    @document["pnxId"].parameterize
  end

  def empty_response?(response)
    response.dig("response", "numFound") == 0
  end
end
