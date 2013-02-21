class CreateOraclePartNums < ActiveRecord::Migration
  def change
    create_table :oracle_part_nums do |t|
      t.string :number
      t.string :description, :limit => 80

      t.timestamps
    end
  end
end
