class AddIndexToCurnitsJnlps < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}curnits", :portal_id
    add_index "#{RAILS_DATABASE_PREFIX}jnlps", :portal_id
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}curnits", :portal_id
    remove_index "#{RAILS_DATABASE_PREFIX}jnlps", :portal_id
  end
end
