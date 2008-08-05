class AddIndexToPods < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}pods", :curnit_id
    add_index "#{RAILS_DATABASE_PREFIX}pods", :uuid
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}pods", :curnit_id
    remove_index "#{RAILS_DATABASE_PREFIX}pods", :uuid
  end
end
