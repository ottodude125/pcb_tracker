class ChangeColumnNames < ActiveRecord::Migration
  def change
    rename_column :part_nums, :prefix, :prefix_old
    rename_column :part_nums, :number, :number_old
    rename_column :part_nums, :dash, :dash_old
  end
end
