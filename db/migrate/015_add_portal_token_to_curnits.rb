class AddPortalTokenToCurnits < ActiveRecord::Migration
  def self.up
    add_column "curnits", :portal_token, :string
  end

  def self.down
    remove_column "curnits", :portal_token
  end
end
