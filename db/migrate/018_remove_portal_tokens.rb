class RemovePortalTokens < ActiveRecord::Migration
  def self.up
    remove_column :sds_curnits, :portal_token
    remove_column :sds_offerings, :portal_token
    remove_column :sds_users, :portal_token
    remove_column :sds_workgroups, :portal_token
  end

  def self.down
    add_column :sds_curnits, :portal_token, :string, :null => false
    add_column :sds_offerings, :portal_token, :string, :null => false
    add_column :sds_users, :portal_token, :string, :null => false
    add_column :sds_workgroups, :portal_token, :string, :null => false
  end
end
