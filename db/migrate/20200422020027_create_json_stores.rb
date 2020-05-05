# frozen_string_literal: true

class CreateJsonStores < ActiveRecord::Migration[5.2]
  def change
    create_table :json_stores do |t|
      t.string :name, index: { unique: true }
      t.text :value
      t.timestamps
    end
  end
end
