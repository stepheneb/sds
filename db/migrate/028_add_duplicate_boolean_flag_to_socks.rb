class AddDuplicateBooleanFlagToSocks < ActiveRecord::Migration
  def self.up
    add_column "socks", :duplicate, :boolean
  end

  def self.down
    remove_column "socks", :duplicate
  end
end
