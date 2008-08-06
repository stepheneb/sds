class BundleContent < ActiveRecord::Migration
  def self.up
    create_table "bundle_contents" do |t|
      t.column :content, :text, :limit => 16777215
    end
    add_column "bundles", :bundle_content_id, :integer
  end

  def self.down
    drop_table "bundle_contents"
    remove_column "bundles", :bundle_content_id
  end
end
