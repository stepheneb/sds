class AddIpAddressToErrorbundle < ActiveRecord::Migration
  def self.up
    add_column :sds_errorbundles, :ip_address, :string
  end

  def self.down
    remove_column :sds_errorbundles, :ip_address  
  end
end
