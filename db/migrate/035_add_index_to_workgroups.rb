class AddIndexToWorkgroups < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}workgroups", :offering_id
    add_index "#{RAILS_DATABASE_PREFIX}workgroups", :portal_id
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}workgroups", :offering_id
    remove_index "#{RAILS_DATABASE_PREFIX}workgroups", :portal_id
  end
end
