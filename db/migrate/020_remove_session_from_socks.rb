class RemoveSessionFromSocks < ActiveRecord::Migration
  def self.up
    remove_column :sds_socks, :session_id
  end

  def self.down
    add_column :sds_socks, :session_id, :integer
  end
end
