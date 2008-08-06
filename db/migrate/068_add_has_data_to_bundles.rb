class AddHasDataToBundles < ActiveRecord::Migration
  def self.up
    add_column "bundles", :has_data, :boolean
    
    # I think this will work -- the key is Bundle.reset_column_information
    say_with_time "Generating values for the new Bundle#has_data attribute ..." do
      Bundle.reset_column_information
      Bundle.find(:all).each {|b| b.has_data = b.socks.count > 0; print "."; b.save}
    end
    
  end

  def self.down
    remove_column "bundles", :has_data
  end
end
