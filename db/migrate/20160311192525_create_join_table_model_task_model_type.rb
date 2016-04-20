class CreateJoinTableModelTaskModelType < ActiveRecord::Migration
  def change
    create_table :model_tasks_model_types, :id => false, :force => true do |t|
      t.references    :model_task,                  :null => false                            
      t.references    :model_type,                  :null => false                            
    end
    add_index :model_tasks_model_types, :model_task_id
    add_index :model_tasks_model_types, :model_type_id
  end
end

