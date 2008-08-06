class AddMoreRimAttributesToPods < ActiveRecord::Migration
  def self.up
    add_column "pods", :rim_shape, :string
  end

  def self.down
    remove_column "socks", :rim_shape
  end
end
