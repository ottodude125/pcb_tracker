class AddColumnToFabIsues < ActiveRecord::Migration
  def change
    add_column :fab_issues, :fab_house_id, :integer
  end
end
