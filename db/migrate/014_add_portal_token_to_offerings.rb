class AddPortalTokenToOfferings < ActiveRecord::Migration
  def self.up
    add_column :sds_offerings, :portal_token, :string, :null => false
  end

  def self.down
    remove_column :sds_offerings, :portal_token
  end
end
