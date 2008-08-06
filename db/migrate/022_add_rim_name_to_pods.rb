class AddRimNameToPods < ActiveRecord::Migration
  def self.up
    add_column "pods", :rim_name, :string
  end

  def self.down
    remove_column "socks", :rim_name
  end
end
