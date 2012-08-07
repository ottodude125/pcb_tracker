class RohsThieving < ActiveRecord::Migration
  def self.up
    add_column :board_design_entries, :rohs, :boolean
    add_column :board_design_entries, :thieving, :boolean
    add_column :board_design_entries, :no_copper, :boolean
  end

  def self.down
    remove_column :board_design_entries, :rohs
    remove_column :board_design_entries, :thieving
    remove_column :board_design_entries, :no_copper
  end
end

