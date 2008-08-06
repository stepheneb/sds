class AddProcessErrorToBundles < ActiveRecord::Migration
  def self.up
    add_column "bundles", :processing_error, :text
  end

  def self.down
    remove_column "bundles", :processing_error
  end
end
