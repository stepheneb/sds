class RemovePortalTokens < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :portal_token
    remove_column "#{RAILS_DATABASE_PREFIX}offerings", :portal_token
    remove_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_token
    remove_column "#{RAILS_DATABASE_PREFIX}workgroups", :portal_token
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :portal_token, :string
    add_column "#{RAILS_DATABASE_PREFIX}offerings", :portal_token, :string
    add_column "#{RAILS_DATABASE_PREFIX}sail_users", :portal_token, :string
    add_column "#{RAILS_DATABASE_PREFIX}workgroups", :portal_token, :string
  end
end
