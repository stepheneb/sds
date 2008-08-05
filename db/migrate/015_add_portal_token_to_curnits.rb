class AddPortalTokenToCurnits < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :portal_token, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :portal_token
  end
end
