class AddDuplicateBooleanFlagToSocks < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}socks", :duplicate, :boolean
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :duplicate
  end
end
