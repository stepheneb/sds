class AddIpAddressToErrorbundle < ActiveRecord::Migration
  def self.up
    add_column "errorbundles", :ip_address, :string
  end

  def self.down
    remove_column "errorbundles", :ip_address  
  end
end
