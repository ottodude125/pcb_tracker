class AddFirCompleteToDesigns < ActiveRecord::Migration
  def change
    add_column :designs, :fir_complete, :boolean
  end
end
