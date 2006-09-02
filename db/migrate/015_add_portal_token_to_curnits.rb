class AddPortalTokenToCurnits < ActiveRecord::Migration
  def self.up
    add_column :sds_curnits, :portal_token, :string, :null => false
  end

  def self.down
    remove_column :sds_curnits, :portal_token
  end
end
