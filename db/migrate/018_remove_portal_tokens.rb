class RemovePortalTokens < ActiveRecord::Migration
  def self.up
    remove_column "curnits", :portal_token
    remove_column "offerings", :portal_token
    remove_column "sail_users", :portal_token
    remove_column "workgroups", :portal_token
  end

  def self.down
    add_column "curnits", :portal_token, :string
    add_column "offerings", :portal_token, :string
    add_column "sail_users", :portal_token, :string
    add_column "workgroups", :portal_token, :string
  end
end
