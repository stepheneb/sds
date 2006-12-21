class AddOpenCloseDatesToOffering < ActiveRecord::Migration
  def self.up
    add_column :sds_offerings, :open_offering, :datetime
    add_column :sds_offerings, :close_offering, :datetime      
    
    Offering.find_all.each do |o|
      o.open_offering = o.created_at
      o.save
    end
  end

  def self.down
    remove_column :sds_offerings, :open_offering
    remove_column :sds_offerings, :close_offering
  end
end
