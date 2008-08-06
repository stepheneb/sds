class RemovePortalUsername < ActiveRecord::Migration
  def self.up
    remove_column "sail_users", :portal_username
  end

  def self.down
    add_column "sail_users", :portal_username, :string
  end
end
