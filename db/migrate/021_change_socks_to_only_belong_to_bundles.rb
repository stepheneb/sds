class ChangeSocksToOnlyBelongToBundles < ActiveRecord::Migration
  def self.up
    remove_column "socks", :offering_id
    remove_column "socks", :workgroup_id
    remove_column "socks", :rim_id
    add_column "socks", :bundle_id, :integer
  end

  def self.down
    add_column "socks", :offering_id, :integer
    add_column "socks", :workgroup_id, :integer
    add_column "socks", :rim_id, :integer
    remove_column "socks", :bundle_id
  end
end
