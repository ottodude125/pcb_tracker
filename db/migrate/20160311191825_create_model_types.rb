class CreateModelTypes < ActiveRecord::Migration
  def change
    create_table :model_types do |t|
      t.string  "name"
      t.boolean "active"

      t.timestamps
    end
  end
end
