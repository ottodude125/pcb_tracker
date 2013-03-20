class EcnWidth < ActiveRecord::Migration
  def self.up
    change_column :designs, :eco_number, :string, :limit => 10
  end

  def self.down
    change_column :designs, :eco_number, :string, :limit => 7
  end
end
