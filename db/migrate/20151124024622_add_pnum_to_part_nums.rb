class AddPnumToPartNums < ActiveRecord::Migration
  def change
    add_column :part_nums, :pnum, :string
  end
end
