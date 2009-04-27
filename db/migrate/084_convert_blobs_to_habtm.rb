class ConvertBlobsToHabtm < ActiveRecord::Migration
  def self.up
    create_table :blobs_bundles, :id => false do |t|
      t.integer :blob_id
      t.integer :bundle_id
      t.timestamps
    end
    
    remove_column :blobs, :bundle_id
  end

  def self.down
    drop_table :blobs_bundles
    
    add_column :blobs, :bundle_id, :integer
  end
end
