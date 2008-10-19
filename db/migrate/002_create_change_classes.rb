class CreateChangeClasses < ActiveRecord::Migration
  
  def self.up
    
    create_table :change_classes do |t|
      t.string :name
      t.integer :position
      t.boolean :active
      t.text    :definition

      t.timestamps
    end

    create_table :change_types do |t|
      t.string :name
      t.integer :position
      t.integer :change_class_id
      t.boolean :active
      t.text    :definition

      t.timestamps
    end

    create_table :change_items do |t|
      t.string :name
      t.integer :position
      t.integer :change_type_id
      t.boolean :active
      t.text    :definition

      t.timestamps
    end

    create_table :change_details do |t|
      t.string :name
      t.integer :position
      t.integer :change_item_id
      t.boolean :active
      t.text    :definition

      t.timestamps
    end

  end

  def self.down
    drop_table :change_classes
    drop_table :change_types
    drop_table :change_items
    drop_table :change_details
  end
end
