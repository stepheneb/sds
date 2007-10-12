class AddIndexOfferingAttributes < ActiveRecord::Migration
  def self.up
    add_index :sds_offerings_attributes, :offering_id
  end

  def self.down
    remove_index :sds_offerings_attributes, :offering_id
  end
end