class AddPortalUsernameToUsers < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_username, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_username
  end
end
