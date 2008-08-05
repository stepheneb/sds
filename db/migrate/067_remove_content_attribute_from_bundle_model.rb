class RemoveContentAttributeFromBundleModel < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :content
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :content, :text, :limit => 16777215 # 16MB
  end
end
