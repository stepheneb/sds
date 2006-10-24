class AddRimNameToPods < ActiveRecord::Migration
  def self.up
    add_column :sds_pods, :rim_name, :string
  end

  def self.down
    remove_column :sds_socks, :rim_name
  end
end
