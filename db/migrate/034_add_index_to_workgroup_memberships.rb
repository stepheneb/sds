class AddIndexToWorkgroupMemberships < ActiveRecord::Migration
  def self.up
    add_index "workgroup_memberships", :sail_user_id
    add_index "workgroup_memberships", :workgroup_id
  end

  def self.down
    remove_index "workgroup_memberships", :sail_user_id
    remove_index "workgroup_memberships", :workgroup_id
  end
end
