class DesignChanges < ActiveRecord::Migration
  
  def self.up
    
    create_table :design_changes do |t|
      t.integer   :design_id,         :default => 0
      t.integer   :change_detail_id,  :default => 0
      t.integer   :change_item_id,    :default => 0
      t.integer   :change_type_id,    :default => 0
      t.integer   :change_class_id,   :default => 0
      t.integer   :designer_id,       :default => 0
      t.integer   :manager_id,        :default => 0
      t.boolean   :approved,          :default => false
      t.float     :hours,             :default => 0.0,         :scale => 1
      t.string    :impact,            :default => 'None',      :limit => 8 
      t.timestamp :approved_at
      t.text      :designer_comment
      t.text      :manager_comment

      t.timestamps
    end

  end

  def self.down
    drop_table :design_changes
  end
end
