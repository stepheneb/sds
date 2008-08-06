class AddIndexToCurnitsJnlps < ActiveRecord::Migration
  def self.up
    add_index "curnits", :portal_id
    add_index "jnlps", :portal_id
  end

  def self.down
    remove_index "curnits", :portal_id
    remove_index "jnlps", :portal_id
  end
end
