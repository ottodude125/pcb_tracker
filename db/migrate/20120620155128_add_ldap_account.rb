class AddLdapAccount < ActiveRecord::Migration
  def up
    add_column :users, :ldap_account, :string
  end

  def down
    remove_column :users, :ldap_account
  end
end
