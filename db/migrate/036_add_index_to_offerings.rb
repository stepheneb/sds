class AddIndexToOfferings < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}offerings", :portal_id
    add_index "#{RAILS_DATABASE_PREFIX}offerings", :curnit_id
    add_index "#{RAILS_DATABASE_PREFIX}offerings", :jnlp_id
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}offerings", :portal_id
    remove_index "#{RAILS_DATABASE_PREFIX}offerings", :curnit_id
    remove_index "#{RAILS_DATABASE_PREFIX}offerings", :jnlp_id
  end
end
