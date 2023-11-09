# frozen_string_literal: true

module NoteHelper
  def electronic_notes(type)
    name = "#{type}_notes"

    Rails.cache.fetch(name) do
      JsonStore.find_by(name: name)&.value || {}
    end
  end

  def service_unavailable_fields
    [ "service_temporarily_unavailable", "service_unavailable_date", "service_unavailable_reason" ]
  end

  def get_collection_notes(id)
    (electronic_notes("collection")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_service_notes(id)
    (electronic_notes("service")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_unavailable_notes(id)
    (electronic_notes("service")[id] || {})
      .slice("service_unavailable_reason")
      .select { |k, v| v.present? }.values
      .map { |reason| "This service is temporarily unavailable due to: #{reason}." }
  end

  def render_electronic_notes(field)
    collection_id = field["collection_id"]
    service_id = field["service_id"]

    public_notes = field["public_note"]
    authentication_notes = field["authentication_note"]
    collection_notes = get_collection_notes(collection_id)
    service_notes = get_service_notes(service_id)
    unavailable_notes = get_unavailable_notes(service_id)

    if collection_notes.present? ||
        service_notes.present? ||
        public_notes.present? ||
        authentication_notes.present? ||
        unavailable_notes.present?

      render partial: "electronic_notes", locals: {
        collection_notes: collection_notes,
        service_notes: service_notes,
        public_notes: public_notes,
        authentication_notes: authentication_notes,
        unavailable_notes: unavailable_notes,
      }
    end
  end
end
