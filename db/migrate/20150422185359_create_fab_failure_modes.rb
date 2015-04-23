class CreateFabFailureModes < ActiveRecord::Migration
  def change
    create_table :fab_failure_modes do |t|
      t.string :name,      :null => false
      t.boolean :active,   :default => true 
      t.timestamps
    end
  end
end
