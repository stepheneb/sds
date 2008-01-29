class CreateConfigVersions < ActiveRecord::Migration
  def self.up
    create_table :sds_config_versions do |t|
      t.column :name, :string
      t.column :version, :float
      t.column :template, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :sds_config_versions
  end
end
