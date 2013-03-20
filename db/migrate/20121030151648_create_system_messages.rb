class CreateSystemMessages < ActiveRecord::Migration
  def change
    create_table :system_messages do |t|
      t.string :message_type
      t.string :title
      t.text :body
      t.datetime :valid_from
      t.datetime :valid_until
      t.references :user
      t.timestamps
    end
  end
end
