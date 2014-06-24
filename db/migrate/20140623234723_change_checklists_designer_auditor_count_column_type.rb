class ChangeChecklistsDesignerAuditorCountColumnType < ActiveRecord::Migration
  def up
    change_column :checklists, :designer_auditor_count, :integer, :limit => 2, :default => 0, :null => false
  end

  def down
    change_column :checklists, :designer_auditor_count, :integer, :limit => 1, :default => 0, :null => false
  end
end
