class AddEcoTaskIdIndex < ActiveRecord::Migration
  def change
    add_index :eco_documents, :eco_task_id, :name => 'eco_task_id'
    add_index :eco_comments,  :eco_task_id, :name => 'eco_task_id'
  end

end
