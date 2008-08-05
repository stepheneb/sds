class AddPortalTokenToOfferings < ActiveRecord::Migration
  def self.up
#    add_column "#{RAILS_DATABASE_PREFIX}offerings", :portal_token, :string
    add_column "#{RAILS_DATABASE_PREFIX}offerings", :portal_token, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}offerings", :portal_token
  end
end
