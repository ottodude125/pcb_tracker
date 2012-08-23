class AddLdapOptout < ActiveRecord::Migration
  def up
    add_column :users, :ldap_optout, :boolean, :default => 0
  end

  def down
    remove_column :user, :ldap_optout
  end
end
