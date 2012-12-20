class AddAsicFpgaToBoardDesignEntry < ActiveRecord::Migration
  def change
    add_column :board_design_entries, :asic_fpga, :boolean, :default => 0 
  end
end
