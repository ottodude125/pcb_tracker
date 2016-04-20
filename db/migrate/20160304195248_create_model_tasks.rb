class CreateModelTasks < ActiveRecord::Migration
  def change
    create_table :model_tasks do |t|
      t.string      :request_number,                  :null => false
      t.text        :description
      t.string      :mfg
      t.string      :mfg_num
      t.text        :cae_model
      t.text        :cad_model
      t.boolean     :closed,      :default => false,  :null => false
      t.datetime    :closed_at
      t.boolean     :completed,   :default => false,  :null => false
      t.datetime    :completed_at
      t.references  :user,                            :null => false     
      
      t.timestamps
    end
  end
end
