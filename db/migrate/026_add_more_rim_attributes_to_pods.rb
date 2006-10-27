class AddMoreRimAttributesToPods < ActiveRecord::Migration
  def self.up
    add_column :sds_pods, :rim_shape, :string
  end

  def self.down
    remove_column :sds_socks, :rim_shape
  end
end
