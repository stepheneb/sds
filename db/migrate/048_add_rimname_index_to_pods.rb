class AddRimnameIndexToPods < ActiveRecord::Migration
  def self.up
    add_index :sds_pods, :rim_name
  end

  def self.down
    remove_index :sds_pods, :rim_name
  end
end
