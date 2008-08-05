class AddIndexOfferingAttributes < ActiveRecord::Migration
  def self.up
    add_index "#{RAILS_DATABASE_PREFIX}offerings_attributes", :offering_id
  end

  def self.down
    remove_index "#{RAILS_DATABASE_PREFIX}offerings_attributes", :offering_id
  end
end