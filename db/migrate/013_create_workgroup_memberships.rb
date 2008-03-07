class CreateWorkgroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :sds_workgroup_memberships do |t|
      t.column :sail_user_id, :integer
      t.column :workgroup_id, :integer
      t.column :version, :integer
    end
  end

  def self.down
    drop_table :sds_workgroup_memberships
  end
end
