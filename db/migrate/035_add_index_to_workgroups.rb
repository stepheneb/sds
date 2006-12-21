class AddIndexToWorkgroups < ActiveRecord::Migration
  def self.up
    add_index :sds_workgroups, :offering_id
    add_index :sds_workgroups, :portal_id
  end

  def self.down
    remove_index :sds_workgroups, :offering_id
    remove_index :sds_workgroups, :portal_id
  end
end
