class CreateDesignFabHouses < ActiveRecord::Migration
  def change
    create_table :design_fab_houses do |t|
      t.references  :design,    :null => false                            
      t.references  :fab_house, :null => false                            
      t.boolean     :approved,  :null => false, :default => 0
      t.timestamps

    end
    add_index :design_fab_houses, :design_id
    add_index :design_fab_houses, :fab_house_id
    
    # Copy data from current join table to this new replacement table
    execute "INSERT design_fab_houses (design_id, fab_house_id) SELECT design_id, fab_house_id FROM designs_fab_houses"

  end
end
