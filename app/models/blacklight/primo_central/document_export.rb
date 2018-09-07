# frozen_string_literal: true

module Blacklight::PrimoCentral::DocumentExport
  def self.extended(document)
    document.will_export_as(:refworks, "text/plain")
  end

  def export_as_refworks
    tags = []
    to_refworks.each { |t, value|
      if value.is_a? Array
        value.each { |v| tags << "#{t} #{v}" }
      else
        tags << "#{t} #{value}"
      end
    }
    tags.join("\n")
  end


  private
    def to_refworks
      self.select { |f, v| refwork_tags.keys.include? f }
        .select { |f, v| !v.nil? && !v.empty? }
        .map { |f, v| [refwork_tags[f], v] }
    end

    def refwork_tags
      config_tags = blacklight_config
        .show_fields.select { |k, v| v[:refwork_tag] }
        .map { |k, v| [k, v[:refwork_tag]] }.to_h

      { "title" => :T1, "pnxId" => :ID }
        .merge(config_tags)
    end
end
