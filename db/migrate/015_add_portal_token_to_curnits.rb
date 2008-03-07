class AddPortalTokenToCurnits < ActiveRecord::Migration
  def self.up
    add_column :sds_curnits, :portal_token, :string
  end

  def self.down
    remove_column :sds_curnits, :portal_token
  end
end
