class AddProcessStatusToBundles < ActiveRecord::Migration
  def self.up
    add_column :sds_bundles, :process_status, :integer
  end

  def self.down
    remove_column :sds_bundles, :process_status 
  end
end
