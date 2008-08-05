class AddUpdatedAt < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}bundle_contents", :created_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}bundle_contents", :updated_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :updated_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}errorbundles", :updated_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}pods", :created_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}pods", :updated_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}rims", :created_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}rims", :updated_at, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}socks", :updated_at, :datetime
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}bundle_contents", :created_at
    remove_column "#{RAILS_DATABASE_PREFIX}bundle_contents", :updated_at
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :updated_at
    remove_column "#{RAILS_DATABASE_PREFIX}errorbundles", :updated_at
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :created_at
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :updated_at
    remove_column "#{RAILS_DATABASE_PREFIX}rims", :created_at
    remove_column "#{RAILS_DATABASE_PREFIX}rims", :updated_at
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :updated_at
  end
end
