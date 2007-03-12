class AddProcessErrorToBundles < ActiveRecord::Migration
  def self.up
    add_column :sds_bundles, :processing_error, :text
  end

  def self.down
    remove_column :sds_bundles, :processing_error
  end
end
