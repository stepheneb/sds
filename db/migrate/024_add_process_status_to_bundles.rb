class AddProcessStatusToBundles < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :process_status, :integer
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :process_status 
  end
end
