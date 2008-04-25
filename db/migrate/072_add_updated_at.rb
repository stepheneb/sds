class AddUpdatedAt < ActiveRecord::Migration
  def self.up
    add_column :sds_bundle_contents, :created_at, :datetime
    add_column :sds_bundle_contents, :updated_at, :datetime
    add_column :sds_bundles, :updated_at, :datetime
    add_column :sds_errorbundles, :updated_at, :datetime
    add_column :sds_pods, :created_at, :datetime
    add_column :sds_pods, :updated_at, :datetime
    add_column :sds_rims, :created_at, :datetime
    add_column :sds_rims, :updated_at, :datetime
    add_column :sds_socks, :updated_at, :datetime
  end

  def self.down
    remove_column :sds_bundle_contents, :created_at
    remove_column :sds_bundle_contents, :updated_at
    remove_column :sds_bundles, :updated_at
    remove_column :sds_errorbundles, :updated_at
    remove_column :sds_pods, :created_at
    remove_column :sds_pods, :updated_at
    remove_column :sds_rims, :created_at
    remove_column :sds_rims, :updated_at
    remove_column :sds_socks, :updated_at
  end
end
