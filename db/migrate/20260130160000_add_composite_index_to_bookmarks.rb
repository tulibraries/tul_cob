# frozen_string_literal: true

class AddCompositeIndexToBookmarks < ActiveRecord::Migration[7.1]
  def change
    add_index :bookmarks, [:user_id, :user_type, :document_type, :document_id], name: "index_bookmarks_on_user_and_document"
  end
end
