class AddPodIdToSocks < ActiveRecord::Migration
  def self.up
    add_column :sds_socks, :pod_id, :integer
  end

  def self.down
    remove_column :sds_socks, :pod_id  
  end
end
