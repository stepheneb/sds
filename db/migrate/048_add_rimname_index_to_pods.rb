class AddRimnameIndexToPods < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}pods", :rim_name
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}pods", :rim_name
  end
end
