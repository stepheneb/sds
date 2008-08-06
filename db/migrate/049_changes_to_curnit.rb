class ChangesToCurnit < ActiveRecord::Migration
  def self.up
    remove_column "curnits", :filename
    
  end

  def self.down
    add_column "curnits", :filename, :string
  end
end
