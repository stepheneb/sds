class AddIndexToSocks < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}socks", :bundle_id
    add_index "#{RAILS_DATABASE_PREFIX}socks", :pod_id
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}socks", :bundle_id
    add_index "#{RAILS_DATABASE_PREFIX}socks", :pod_id
  end
end
