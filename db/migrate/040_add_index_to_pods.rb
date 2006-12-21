class AddIndexToPods < ActiveRecord::Migration
  def self.up
    add_index :sds_pods, :curnit_id
    add_index :sds_pods, :uuid
  end

  def self.down
    remove_index :sds_pods, :curnit_id
    remove_index :sds_pods, :uuid
  end
end
