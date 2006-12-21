class AddIndexToBundles < ActiveRecord::Migration
  def self.up
    add_index :sds_bundles, :offering_id
    add_index :sds_bundles, :workgroup_id
    add_index :sds_bundles, :workgroup_version
  end

  def self.down
    remove_index :sds_bundles, :offering_id
    remove_index :sds_bundles, :workgroup_id
    remove_index :sds_bundles, :workgroup_version
  end
end
