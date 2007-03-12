class AddPortalUsernameToUsers < ActiveRecord::Migration
  def self.up
    add_column :sds_sail_users, :portal_username, :string, :null => false
  end

  def self.down
    remove_column :sds_sail_users, :portal_username
  end
end
