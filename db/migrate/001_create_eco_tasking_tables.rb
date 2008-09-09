class CreateEcoTaskingTables < ActiveRecord::Migration


  def self.up
    
    #
    # ECO Types
    #
    create_table :eco_types do |t|
      t.column(:name,   :string)
      t.column(:active, :boolean)
    end
    
    #
    # Load the ECO Types that will be supported.  This table is intended
    # to be static
    EcoType.create :name => 'Schematic',           :active => 1
    EcoType.create :name => 'Assembly Drawing',    :active => 1
    EcoType.create :name => 'Fabrication Drawing', :active => 1
    
    
    #
    # ECO Tasks
    #
    create_table :eco_tasks do |t|
      t.string      :number,           :limit => 16
      t.string      :pcb_revision,     :limit =>  2
      t.string      :pcba_part_number, :limit => 10
      t.string      :directory_name,   :limit => 13
      t.integer     :eco_type_id
      t.boolean     :completed,        :null => false
      t.boolean     :closed,           :null => false
      t.boolean     :specified,        :null => false
      t.boolean     :cuts_and_jumps,   :null => false
      t.text        :document_link
      t.timestamp   :screened_at
      t.timestamp   :started_at
      t.timestamp   :completed_at
      t.timestamp   :closed_at
      t.timestamps
    end
    
    
    #
    # ECO Tasks/Users Relationship
    # 
    # Supports email CC list.
    #
    create_table :eco_tasks_users, { :id => false } do |t|
      t.column(:eco_task_id, :integer,  :null => false)
      t.column(:user_id,     :integer,  :null => false)
    end

    
    #
    # ECO Task/ECO Type Relationship
    #
    create_table :eco_tasks_eco_types, { :id => false } do |t|
      t.column(:eco_task_id, :integer,  :null => false)
      t.column(:eco_type_id, :integer,  :null => false)
    end

    
    #
    # ECO Comments
    #
    create_table :eco_comments do |t|
      t.column(:eco_task_id, :integer,   :null => false)
      t.column(:user_id,     :integer,   :null => false)
      t.column(:created_at,  :timestamp)
      t.column(:comment,     :text)
    end
    
    
    #
    # ECO Documents
    #
    create_table :eco_documents do |t|
      t.column(:unpacked,      :integer,   :null => false, :limit => 3)
      t.column(:name,          :string,    :null => false, :limit => 100)
      t.column(:content_type,  :string,    :null => false, :limit => 100)
      t.column(:user_id,       :integer,   :null => false)
      t.column(:eco_task_id,   :integer,   :null => false)
      t.column(:created_at,    :timestamp)
      t.column(:specification, :boolean,   :default => 0)
      t.column(:data,          :binary,    :null => false, :limit => 16.megabyte)
    end

  end
  
  
  
  def self.down
    
    drop_table :eco_types
    drop_table :eco_tasks
    drop_table :eco_tasks_eco_types
    drop_table :eco_tasks_users
    drop_table :eco_comments
    drop_table :eco_documents

  end
  
  
end
