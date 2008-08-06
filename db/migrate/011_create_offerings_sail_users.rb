class CreateOfferingsSailUsers < ActiveRecord::Migration
  def self.up
    create_table "offerings_sail_users", :id => false do |t|
      t.column :offering_id, :integer
      t.column :sail_user_id, :integer
    end
  end

  def self.down
    drop_table "offerings_sail_users"
  end
end
