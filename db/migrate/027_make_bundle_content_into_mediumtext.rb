class MakeBundleContentIntoMediumtext < ActiveRecord::Migration
  def self.up
    change_column :sds_bundles, :content, :text, :limit => 16777215
  end

  def self.down
    change_column :sds_bundles, :content, :text
  end
end

