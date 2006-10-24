class ChangeSocksToOnlyBelongToBundles < ActiveRecord::Migration
  def self.up
    remove_column :sds_socks, :offering_id
    remove_column :sds_socks, :workgroup_id
    remove_column :sds_socks, :rim_id
    add_column :sds_socks, :bundle_id, :integer
  end

  def self.down
    add_column :sds_socks, :offering_id, :integer
    add_column :sds_socks, :workgroup_id, :integer
    add_column :sds_socks, :rim_id, :integer
    remove_column :sds_socks, :bundle_id
  end
end
