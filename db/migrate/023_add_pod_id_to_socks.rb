class AddPodIdToSocks < ActiveRecord::Migration
  def self.up
    add_column "socks", :pod_id, :integer
  end

  def self.down
    remove_column "socks", :pod_id  
  end
end
