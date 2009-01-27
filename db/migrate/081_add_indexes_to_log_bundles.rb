class AddIndexesToLogBundles < ActiveRecord::Migration
  def self.up
    add_index :log_bundles, :bundle_id
    add_index :log_bundles, :workgroup_id
    add_index :log_bundles, :sail_session_uuid
    add_index :log_bundles, :sail_curnit_uuid
  end

  def self.down
    remove_index :log_bundles, :bundle_id
    remove_index :log_bundles, :workgroup_id
    remove_index :log_bundles, :sail_session_uuid
    remove_index :log_bundles, :sail_curnit_uuid
  end
end
