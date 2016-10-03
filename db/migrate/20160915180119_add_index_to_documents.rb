class AddIndexToDocuments < ActiveRecord::Migration
  def change
    add_index :documents, :created_on
  end
end
