class MakeBundleContentIntoMediumtext < ActiveRecord::Migration
  def self.up
    change_column "#{RAILS_DATABASE_PREFIX}bundles", :content, :text, :limit => 16777215 # 16MB
    change_column "#{RAILS_DATABASE_PREFIX}socks", :value, :text, :limit => 2097151 # 2 MB *** changed after the fact
  end

  def self.down
    change_column "#{RAILS_DATABASE_PREFIX}bundles", :content, :text
    change_column "#{RAILS_DATABASE_PREFIX}socks", :value, :text
  end
end

