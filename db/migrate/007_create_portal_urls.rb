class CreatePortalUrls < ActiveRecord::Migration
  def self.up
    create_table "portal_urls" do |t|
      t.column :portal_id, :integer
      t.column :name, :string, :limit => 60
      t.column :url, :string, :limit => 120
    end
  end

  def self.down
    drop_table "portal_urls"
  end
end
