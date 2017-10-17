# frozen_string_literal: true

class AddAlmaIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :alma_id, :string
  end
end
