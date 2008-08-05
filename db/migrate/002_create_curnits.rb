class CreateCurnits < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}curnits" do |t|
      t.column :portal_id, :integer
      t.column :name, :string, :limit => 60
      t.column :url, :string, :limit => 256
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}curnits"
  end
end
