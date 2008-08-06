class AddIndexToPods < ActiveRecord::Migration
  def self.up
    add_index "pods", :curnit_id
    add_index "pods", :uuid
  end

  def self.down
    remove_index "pods", :curnit_id
    remove_index "pods", :uuid
  end
end
