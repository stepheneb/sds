class AddDuplicateBooleanFlagToSocks < ActiveRecord::Migration
  def self.up
    add_column :sds_socks, :duplicate, :boolean
  end

  def self.down
    remove_column :sds_socks, :duplicate
  end
end
