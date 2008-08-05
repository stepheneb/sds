class AddOpenCloseDatesToOffering < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}offerings", :open_offering, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}offerings", :close_offering, :datetime      
    
    Offering.find(:all).each do |o|
      o.open_offering = o.created_at
      o.save
    end
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}offerings", :open_offering
    remove_column "#{RAILS_DATABASE_PREFIX}offerings", :close_offering
  end
end
