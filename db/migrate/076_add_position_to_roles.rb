class AddPositionToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :position, :integer
  end

  def self.down
    remove_column :roles, :position
  end
end
