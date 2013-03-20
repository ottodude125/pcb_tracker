class AddMessageSeenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :message_seen, :datetime

  end
end
