class AddPortalTokenToOfferings < ActiveRecord::Migration
  def self.up
#    add_column "offerings", :portal_token, :string
    add_column "offerings", :portal_token, :string
  end

  def self.down
    remove_column "offerings", :portal_token
  end
end
