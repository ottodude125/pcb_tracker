class AddDefaultsToRohsThieving < ActiveRecord::Migration
  def change
    change_column_default(:board_design_entries, :rohs, 1)
    change_column_default(:board_design_entries, :thieving, 0)
    change_column_default(:board_design_entries, :no_copper, 0)
  end
end
