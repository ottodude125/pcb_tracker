class WidenEcoDirField < ActiveRecord::Migration
  def self.up
    change_column :eco_tasks, :directory_name, :string, :limit => 40
  end

  def self.down
     change_column :eco_tasks, :directory_name, :string, :limit => 25
  end
end
