class AddIndexToWorkgroupMemberships < ActiveRecord::Migration
  def self.up
    add_index :sds_workgroup_memberships, :user_id
    add_index :sds_workgroup_memberships, :workgroup_id
  end

  def self.down
    remove_index :sds_workgroup_memberships, :user_id
    remove_index :sds_workgroup_memberships, :workgroup_id
  end
end
