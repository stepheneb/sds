class RemovePortalUsername < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_username
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_username, :string
  end
end
