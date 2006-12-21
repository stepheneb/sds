class AddIndexToSocks < ActiveRecord::Migration
  def self.up
    add_index :sds_socks, :bundle_id
    add_index :sds_socks, :pod_id
  end

  def self.down
    remove_index :sds_socks, :bundle_id
    add_index :sds_socks, :pod_id
  end
end
