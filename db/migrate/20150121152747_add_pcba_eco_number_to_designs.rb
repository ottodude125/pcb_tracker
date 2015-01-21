class AddPcbaEcoNumberToDesigns < ActiveRecord::Migration
  
  def change
    add_column :designs, :pcba_eco_number, :string, null: true, :default => '', :limit => 10
  end

end
