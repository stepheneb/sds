class AddKeyDescriptionToConfigVersions < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}config_versions", :key, :string
    add_column "#{RAILS_DATABASE_PREFIX}config_versions", :description, :text
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}config_versions", :key
    remove_column "#{RAILS_DATABASE_PREFIX}config_versions", :description
  end
end
