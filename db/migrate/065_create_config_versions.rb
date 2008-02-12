class CreateConfigVersions < ActiveRecord::Migration
  def self.up
    create_table :sds_config_versions do |t|
      t.column :name, :string
      t.column :version, :float
      t.column :template, :text
      t.timestamps
    end
    
    puts "\nBE SURE TO RUN rake sds:setup_config_versions !!!\n"
  end

  def self.down
    drop_table :sds_config_versions
  end
end
