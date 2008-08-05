class AddIpAddressToErrorbundle < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}errorbundles", :ip_address, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}errorbundles", :ip_address  
  end
end
