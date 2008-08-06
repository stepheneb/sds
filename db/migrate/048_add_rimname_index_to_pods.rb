class AddRimnameIndexToPods < ActiveRecord::Migration
  def self.up
    add_index "pods", :rim_name
  end

  def self.down
    remove_index "pods", :rim_name
  end
end
