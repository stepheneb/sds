class AddIndexToSocks < ActiveRecord::Migration
  def self.up
    add_index "socks", :bundle_id
    add_index "socks", :pod_id
  end

  def self.down
    remove_index "socks", :bundle_id
    add_index "socks", :pod_id
  end
end
