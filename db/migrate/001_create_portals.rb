class CreatePortals < ActiveRecord::Migration
  def self.up
    create_table :sds_portals do |t|
      t.column :name, :string
      t.column :auth_username, :string
      t.column :auth_password, :string
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :sds_portals
  end
end
