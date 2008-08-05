class ChangeSocksToOnlyBelongToBundles < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :offering_id
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :workgroup_id
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :rim_id
    add_column "#{RAILS_DATABASE_PREFIX}socks", :bundle_id, :integer
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}socks", :offering_id, :integer
    add_column "#{RAILS_DATABASE_PREFIX}socks", :workgroup_id, :integer
    add_column "#{RAILS_DATABASE_PREFIX}socks", :rim_id, :integer
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :bundle_id
  end
end
