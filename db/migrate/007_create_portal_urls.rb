class CreatePortalUrls < ActiveRecord::Migration
  def self.up
    create_table :sds_portal_urls do |t|
      t.column :portal_id, :integer
      t.column :name, :string, :limit => 60, :null => false
      t.column :url, :string, :limit => 120, :null => false
    end
  end

  def self.down
    drop_table :sds_portal_urls
  end
end
