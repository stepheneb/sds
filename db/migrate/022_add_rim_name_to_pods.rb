class AddRimNameToPods < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}pods", :rim_name, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :rim_name
  end
end
