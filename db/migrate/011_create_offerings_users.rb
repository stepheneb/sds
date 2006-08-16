class CreateOfferingsUsers < ActiveRecord::Migration
  def self.up
    create_table :sds_offerings_users, :id => false do |t|
      t.column :offering_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :sds_offerings_users
  end
end
