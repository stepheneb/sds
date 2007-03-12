class CreateSailUsers < ActiveRecord::Migration
  def self.up
    create_table :sds_sail_users do |t|
      t.column :portal_id, :integer
      t.column :portal_token, :string, :null => false
      t.column :first_name, :string, :limit => 60, :null => false
      t.column :last_name, :string, :limit => 60, :null => false
      t.column :uuid, :string, :limit => 36, :null => false
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :sds_sail_users
  end
end
