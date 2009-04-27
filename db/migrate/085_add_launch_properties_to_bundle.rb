class AddLaunchPropertiesToBundle < ActiveRecord::Migration
  def self.up
    add_column :bundles, :is_otml, :boolean
    add_column :bundles, :maven_jnlp_version, :string
    add_column :bundles, :sds_time, :string
    add_column :bundles, :sailotrunk_otmlurl, :string
    add_column :bundles, :jnlp_properties, :string
    add_column :bundles, :previous_bundle_session_id, :string
  end

  def self.down
    remove_column :bundles, :is_otml
    remove_column :bundles, :maven_jnlp_version
    remove_column :bundles, :sds_time
    remove_column :bundles, :sailotrunk_otmlurl
    remove_column :bundles, :jnlp_properties
    remove_column :bundles, :previous_bundle_session_id
  end
end
