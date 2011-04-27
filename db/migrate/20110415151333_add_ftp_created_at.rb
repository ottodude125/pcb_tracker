class AddFtpCreatedAt < ActiveRecord::Migration
  def self.up
    change_table :ftp_notifications do |t|
      t.timestamps
    end
  end

  def self.down
    remove_column :ftp_notifications, :timestamps
  end
end
