class RohsThieving < ActiveRecord::Migration
  def self.up
    add_column :board_design_entries, :rohs, :boolean
    add_column :board_design_entries, :thieving, :boolean
    add_column :board_design_entries, :no_copper, :boolean
  end

  def self.down
    add_column :board_design_entries, :rohs
    add_column :board_design_entries, :thieving
    add_column :board_design_entries, :no_copper
  end
end

