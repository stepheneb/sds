class AddKeyDescriptionToConfigVersions < ActiveRecord::Migration
  def self.up
    add_column :sds_config_versions, :key, :string
    add_column :sds_config_versions, :description, :text
  end

  def self.down
    remove_column :sds_config_versions, :key
    remove_column :sds_config_versions, :description
  end
end
