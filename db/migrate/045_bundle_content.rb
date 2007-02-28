class BundleContent < ActiveRecord::Migration
  def self.up
    create_table :sds_bundle_contents do |t|
      t.column :bundle_id, :integer
      t.column :content, :text
    end
  end

  def self.down
    drop_table :sds_bundle_contents
  end
end
