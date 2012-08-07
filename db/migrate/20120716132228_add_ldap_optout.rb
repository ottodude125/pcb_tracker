class AddLdapOptout < ActiveRecord::Migration
  def self.up
    add_column :users, :ldap_optout, :boolean, :default => 0
  end

  def self.down
    remove_column :user, :ldap_optout
  end
end
