class CreateBlobs < ActiveRecord::Migration
  def self.up
    create_table :blobs do |t|
      t.binary :content, :limit => 16777215
      t.string :token
      t.integer :bundle_id
      t.timestamps
    end
  end

  def self.down
    drop_table :blobs
  end
end
