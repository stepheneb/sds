class AddIndexToOfferings < ActiveRecord::Migration
  def self.up
    add_index :sds_offerings, :portal_id
    add_index :sds_offerings, :curnit_id
    add_index :sds_offerings, :jnlp_id
  end

  def self.down
    remove_index :sds_offerings, :portal_id
    remove_index :sds_offerings, :curnit_id
    remove_index :sds_offerings, :jnlp_id
  end
end
