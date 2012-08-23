class ChangePhaseIdType < ActiveRecord::Migration
  def up
    change_column :designs, :phase_id, :integer, :limit => 2
  end

  def down
    change_column :designs, :phase_id, :integer, :limit => 1
  end
end
