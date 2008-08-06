class AddPortalAttributes < ActiveRecord::Migration
  def self.up
    add_column "portals", :title, :string
    add_column "portals", :vendor, :string
    add_column "portals", :home_page_url, :string
    add_column "portals", :description, :string
    add_column "portals", :image_url, :string
    add_column "portals", :last_bundle_only, :boolean
  end

  def self.down
    remove_column "portals", :title
    remove_column "portals", :vendor
    remove_column "portals", :home_page_url
    remove_column "portals", :description
    remove_column "portals", :image_url
    remove_column "portals", :last_bundle_only
  end
end
