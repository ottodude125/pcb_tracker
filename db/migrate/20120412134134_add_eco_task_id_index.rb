class AddEcoTaskIdIndex < ActiveRecord::Migration
  def self.up
    add_index :eco_documents, :eco_task_id
  end

  def self.down
  end
end
