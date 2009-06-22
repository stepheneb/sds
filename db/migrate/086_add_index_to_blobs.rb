class AddIndexToBlobs < ActiveRecord::Migration
  def self.up
    puts "Right now, rails doesn't permit setting index sizes, so we have to execute some raw sql"
    execute "ALTER TABLE blobs ADD INDEX index_blobs_on_content(content(100))"
    
    add_index :blobs_bundles, :blob_id
    add_index :blobs_bundles, :bundle_id
  end

  def self.down
    remove_index :blobs, :content
    
    remove_index :blobs_bundles, :blob_id
    remove_index :blobs_bundles, :bundle_id
  end
end
