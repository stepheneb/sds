class ChangesToCurnit < ActiveRecord::Migration
  def self.up
    remove_column :sds_curnits, :filename
    
  end

  def self.down
    add_column :sds_curnits, :filename, :string
  end
end
