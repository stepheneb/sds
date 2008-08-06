class AddKeyDescriptionToConfigVersions < ActiveRecord::Migration
  def self.up
    add_column "config_versions", :key, :string
    add_column "config_versions", :description, :text
  end

  def self.down
    remove_column "config_versions", :key
    remove_column "config_versions", :description
  end
end
