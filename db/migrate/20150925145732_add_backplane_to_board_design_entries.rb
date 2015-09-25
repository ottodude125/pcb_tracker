class AddBackplaneToBoardDesignEntries < ActiveRecord::Migration
  def change
    add_column :board_design_entries, :backplane, :integer, :limit => 1, :default => 0, :null => false
    add_column :board_design_entries, :purchased_assembly_number, :string, :limit => 16, :default => "", :null => false
  end
end
