class CreateModelComments < ActiveRecord::Migration
  def change
    create_table :model_comments do |t|
      t.references :model_task, :default => 0, :null => false
      t.references :user,       :default => 0, :null => false
      t.text       :comment
      
      t.timestamps
    end
  end
end
