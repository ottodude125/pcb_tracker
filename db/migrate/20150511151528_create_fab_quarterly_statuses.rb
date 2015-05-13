class CreateFabQuarterlyStatuses < ActiveRecord::Migration
  def change
    create_table :fab_quarterly_statuses do |t|
      t.integer :quarter, :null => false
      t.integer :year, :null => false
      t.text :status_note
      t.string :image_name

      t.timestamps
    end
  end
end
