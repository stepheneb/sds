class AddHasDataToBundles < ActiveRecord::Migration
  def self.up
    add_column :sds_bundles, :has_data, :boolean
    
    # can't get this to work ??
    # if your database already has data you'll need to run by hand
    # in script/console or script/runner
    # class Bundle < ActiveRecord::Base; end 
    # puts "updating new boolean Bundle attribute: has_data"
    # Bundle.find(:all).each {|b| b.has_data = b.socks.count > 0; print "."; b.save}
  end

  def self.down
    remove_column :sds_bundles, :has_data
  end
end
