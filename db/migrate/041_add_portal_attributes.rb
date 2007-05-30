class AddPortalAttributes < ActiveRecord::Migration
  def self.up
    add_column :sds_portals, :title, :string
    add_column :sds_portals, :vendor, :string
    add_column :sds_portals, :home_page_url, :string
    add_column :sds_portals, :description, :string
    add_column :sds_portals, :image_url, :string
    add_column :sds_portals, :last_bundle_only, :boolean
  end

  def self.down
    remove_column :sds_portals, :title
    remove_column :sds_portals, :vendor
    remove_column :sds_portals, :home_page_url
    remove_column :sds_portals, :description
    remove_column :sds_portals, :image_url
    remove_column :sds_portals, :last_bundle_only
  end
end
