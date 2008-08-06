class RemoveSessionFromSocks < ActiveRecord::Migration
  def self.up
    remove_column "socks", :session_id
  end

  def self.down
    add_column "socks", :session_id, :integer
  end
end
