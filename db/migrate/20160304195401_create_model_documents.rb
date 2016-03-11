class CreateModelDocuments < ActiveRecord::Migration
  def change
    create_table :model_documents do |t|
      t.integer     :unpacked,      :limit => 2,          :default => 0,     :null => false
      t.string      :name,          :limit => 100,        :default => "",    :null => false
      t.string      :content_type,  :limit => 100,        :default => "",    :null => false
      t.references  :user,                                :default => 0,     :null => false
      t.references  :model_task,                          :default => 0,     :null => false
      t.boolean     :specification,                       :default => false
      t.binary      :data,          :limit => 2147483647,                    :null => false
      
      t.timestamps
    end
  end
end
