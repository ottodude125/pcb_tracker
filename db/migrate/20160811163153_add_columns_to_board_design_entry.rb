class AddColumnsToBoardDesignEntry < ActiveRecord::Migration
  class BoardDesignEntry < ActiveRecord::Base
  end

  def up
    add_column :board_design_entries, :exceed_voltage, :boolean, :default => 0, :null => false
    add_column :board_design_entries, :exceed_voltage_details, :text, :default => "", :null => false
    add_column :board_design_entries, :stacked_resource, :boolean, :default => 0, :null => false
    add_column :board_design_entries, :stacked_resource_details, :text, :default => "", :null => false
    add_column :board_design_entries, :exceed_current, :boolean, :default => 0, :null => false
    add_column :board_design_entries, :exceed_current_details, :text, :default => "", :null => false
  
    BoardDesignEntry.find_each do |bde|
      bde.exceed_voltage = 0
      bde.exceed_voltage_details = '' 
      bde.stacked_resource = 0
      bde.stacked_resource_details = ''
      bde.exceed_current = 0
      bde.exceed_current_details = ''
      bde.save!
    end

  end

  def down
    remove_column :board_design_entries, :exceed_voltage, :boolean
    remove_column :board_design_entries, :exceed_voltage_details, :text
    remove_column :board_design_entries, :stacked_resource, :boolean
    remove_column :board_design_entries, :stacked_resource_details, :text
    remove_column :board_design_entries, :exceed_current, :boolean
    remove_column :board_design_entries, :exceed_current_details, :text

  end

end
