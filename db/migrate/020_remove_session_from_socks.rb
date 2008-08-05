class RemoveSessionFromSocks < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :session_id
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}socks", :session_id, :integer
  end
end
