class CreateFabDeliverables < ActiveRecord::Migration
  def change
    create_table :fab_deliverables do |t|
      t.string :name,      :null => false
      t.boolean :active,   :default => true 
      t.integer :parent_id, index: true 
      t.timestamps
    end
  end
end
