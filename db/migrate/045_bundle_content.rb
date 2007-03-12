class BundleContent < ActiveRecord::Migration
  def self.up
    create_table :sds_bundle_contents do |t|
      t.column :content, :text, :limit => 16777215
    end
    add_column :sds_bundles, :bundle_content_id, :integer
  end

  def self.down
    drop_table :sds_bundle_contents
    remove_column :sds_bundles, :bundle_content_id
  end
end
