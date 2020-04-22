# frozen_string_literal: true

class CreateElectronicNotesBags < ActiveRecord::Migration[5.2]
  def change
    create_table :electronic_notes_bags do |t|
      t.string :note_type, index: { unique: true }
      t.json :value
      t.timestamps
    end
  end
end
