class AddIndexToOfferings < ActiveRecord::Migration
  def self.up
    add_index "offerings", :portal_id
    add_index "offerings", :curnit_id
    add_index "offerings", :jnlp_id
  end

  def self.down
    remove_index "offerings", :portal_id
    remove_index "offerings", :curnit_id
    remove_index "offerings", :jnlp_id
  end
end
