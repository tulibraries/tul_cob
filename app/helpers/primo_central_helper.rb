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
    codes = presenter[:document][:languageId]
    codes.map { |c| translate_code(c, "language") }
  end

  def doc_translate_resource_type_code(presenter)
    codes = presenter[:document][:type]
    codes.map { |c| translate_code(c, "resource_type") }
  end

  def index_translate_resource_type_code(presenter)
    codes = doc_translate_resource_type_code(presenter)
    presenter[:document][:format] = codes
    separate_formats(presenter)
  end
end
