class UsersWorkgroups < ActiveRecord::Migration
  def self.up
    create_table :sds_users_workgroups, :id => false do |t|
      t.column :user_id, :integer, :null => false
      t.column :workgroup_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :sds_users_workgroups
  end
end
