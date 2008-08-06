class RemoveContentAttributeFromBundleModel < ActiveRecord::Migration
  def self.up
    remove_column "bundles", :content
  end

  def self.down
    add_column "bundles", :content, :text, :limit => 16777215 # 16MB
  end
end
