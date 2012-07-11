class AddLdapAccount < ActiveRecord::Migration
  def self.up
    add_column :users, :ldap_account, :string
  end

  def self.down
    remove_column :users, :ldap_account
  end
end
