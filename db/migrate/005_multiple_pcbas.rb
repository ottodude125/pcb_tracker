class MultiplePcbas < ActiveRecord::Migration
  def self.up
    create_table :part_nums do | t |
      t.column :prefix,   :string,  :limit => 3
      t.column :number,   :string,  :limit => 3
      t.column :dash,     :string,  :limit => 2
      t.column :revision, :string,  :limit => 1
      t.column :use,      :string,  :limit => 5
      t.column :board_design_entry_id, :integer
      t.column :design_id,             :integer
    end
  end

  def self.down
    drop_table :part_nums
  end
end
