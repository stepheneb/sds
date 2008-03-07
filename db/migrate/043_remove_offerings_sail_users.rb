class RemoveOfferingsSailUsers < ActiveRecord::Migration
  def self.up
    drop_table :sds_offerings_sail_users
  end

  def self.down
    create_table :sds_offerings_sail_users, :id => false do |t|
      t.column :offering_id, :integer
      t.column :sail_user_id, :integer
    end
  end
end
