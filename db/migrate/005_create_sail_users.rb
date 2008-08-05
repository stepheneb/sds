class CreateSailUsers < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}sail_users" do |t|
      t.column :portal_id, :integer
      t.column :portal_token, :string
      t.column :first_name, :string, :limit => 60
      t.column :last_name, :string, :limit => 60
      t.column :uuid, :string, :limit => 36
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}sail_users"
  end
end
