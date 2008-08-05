class ChangesToCurnit < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :filename
    
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :filename, :string
  end
end
