class MakeBundleContentIntoMediumtext < ActiveRecord::Migration
  def self.up
    change_column :sds_bundles, :content, :text, :limit => 16777215 # 16MB
    change_column :sds_socks, :value, :text, :limit => 2097151 # 2 MB *** changed after the fact
  end

  def self.down
    change_column :sds_bundles, :content, :text
    change_column :sds_socks, :value, :text
  end
end

