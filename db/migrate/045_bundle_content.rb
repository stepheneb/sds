class BundleContent < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}bundle_contents" do |t|
      t.column :content, :text, :limit => 16777215
    end
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :bundle_content_id, :integer
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}bundle_contents"
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :bundle_content_id
  end
end
