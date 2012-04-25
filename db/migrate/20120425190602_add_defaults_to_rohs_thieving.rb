class AddDefaultsToRohsThieving < ActiveRecord::Migration
  def self.up
    change_column_default(:board_design_entries, :rohs, 1)
    change_column_default(:board_design_entries, :thieving, 0)
    change_column_default(:board_design_entries, :no_copper, 0)
  end

  def self.down
  end
end
