class RemoveContentAttributeFromBundleModel < ActiveRecord::Migration
  def self.up
    remove_column :sds_bundles, :content
  end

  def self.down
    add_column :sds_bundles, :content, :text, :limit => 16777215 # 16MB
  end
end
