class AddProcessStatusToBundles < ActiveRecord::Migration
  def self.up
    add_column "bundles", :process_status, :integer
  end

  def self.down
    remove_column "bundles", :process_status 
  end
end
