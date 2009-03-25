class AddOriginalBundleContentToBundle < ActiveRecord::Migration
  def self.up
    add_column :bundles, :original_bundle_content_id, :integer
  end

  def self.down
    remove_column :bundles, :original_bundle_content_id
  end
end
