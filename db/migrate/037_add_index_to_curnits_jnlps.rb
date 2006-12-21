class AddIndexToCurnitsJnlps < ActiveRecord::Migration
  def self.up
    add_index :sds_curnits, :portal_id
    add_index :sds_jnlps, :portal_id
  end

  def self.down
    remove_index :sds_curnits, :portal_id
    remove_index :sds_jnlps, :portal_id
  end
end
