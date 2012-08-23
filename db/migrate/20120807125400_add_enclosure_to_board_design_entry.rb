class AddEnclosureToBoardDesignEntry < ActiveRecord::Migration
  def change
    add_column :board_design_entries, :enclosure, :boolean, :default => 0

  end
end
