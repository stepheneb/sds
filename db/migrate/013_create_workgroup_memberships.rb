class CreateWorkgroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :sds_workgroup_memberships do |t|
      t.column :user_id, :integer, :null => false
      t.column :workgroup_id, :integer, :null => false
      t.column :version, :integer, :null => false
    end
  end

  def self.down
    drop_table :sds_workgroup_memberships
  end
end
