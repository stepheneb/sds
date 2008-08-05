class AddIndexToBundles < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}bundles", :offering_id
    add_index "#{RAILS_DATABASE_PREFIX}bundles", :workgroup_id
    add_index "#{RAILS_DATABASE_PREFIX}bundles", :workgroup_version
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}bundles", :offering_id
    remove_index "#{RAILS_DATABASE_PREFIX}bundles", :workgroup_id
    remove_index "#{RAILS_DATABASE_PREFIX}bundles", :workgroup_version
  end
end
