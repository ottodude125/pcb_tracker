class AddDescriptionToPartNums < ActiveRecord::Migration
  def change
    add_column :part_nums, :description, :string, :limit => 80

  end
end
