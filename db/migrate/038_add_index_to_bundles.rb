class AddIndexToBundles < ActiveRecord::Migration
  def self.up
    add_index "bundles", :offering_id
    add_index "bundles", :workgroup_id
    add_index "bundles", :workgroup_version
  end

  def self.down
    remove_index "bundles", :offering_id
    remove_index "bundles", :workgroup_id
    remove_index "bundles", :workgroup_version
  end
end
