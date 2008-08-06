class AddUpdatedAt < ActiveRecord::Migration
  def self.up
    add_column "bundle_contents", :created_at, :datetime
    add_column "bundle_contents", :updated_at, :datetime
    add_column "bundles", :updated_at, :datetime
    add_column "errorbundles", :updated_at, :datetime
    add_column "pods", :created_at, :datetime
    add_column "pods", :updated_at, :datetime
    add_column "rims", :created_at, :datetime
    add_column "rims", :updated_at, :datetime
    add_column "socks", :updated_at, :datetime
  end

  def self.down
    remove_column "bundle_contents", :created_at
    remove_column "bundle_contents", :updated_at
    remove_column "bundles", :updated_at
    remove_column "errorbundles", :updated_at
    remove_column "pods", :created_at
    remove_column "pods", :updated_at
    remove_column "rims", :created_at
    remove_column "rims", :updated_at
    remove_column "socks", :updated_at
  end
end
