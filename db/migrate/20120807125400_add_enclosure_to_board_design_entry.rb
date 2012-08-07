class AddEnclosureToBoardDesignEntry < ActiveRecord::Migration
  def self.up
    add_column :board_design_entries, :enclosure, :boolean
  end

  def self.down
    remove_column :board_design_entries, :enclosure, :boolean
  end
    
end
