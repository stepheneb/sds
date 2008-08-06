class AddIndexToWorkgroups < ActiveRecord::Migration
  def self.up
    add_index "workgroups", :offering_id
    add_index "workgroups", :portal_id
  end

  def self.down
    remove_index "workgroups", :offering_id
    remove_index "workgroups", :portal_id
  end
end
