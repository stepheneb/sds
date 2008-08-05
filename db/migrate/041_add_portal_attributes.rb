class AddPortalAttributes < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}portals", :title, :string
    add_column "#{RAILS_DATABASE_PREFIX}portals", :vendor, :string
    add_column "#{RAILS_DATABASE_PREFIX}portals", :home_page_url, :string
    add_column "#{RAILS_DATABASE_PREFIX}portals", :description, :string
    add_column "#{RAILS_DATABASE_PREFIX}portals", :image_url, :string
    add_column "#{RAILS_DATABASE_PREFIX}portals", :last_bundle_only, :boolean
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :title
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :vendor
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :home_page_url
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :description
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :image_url
    remove_column "#{RAILS_DATABASE_PREFIX}portals", :last_bundle_only
  end
end
