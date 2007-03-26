class CreateCurnits < ActiveRecord::Migration
  def self.up
    create_table :sds_curnits do |t|
      t.column :portal_id, :integer
      t.column :name, :string, :limit => 60, :null => false
      t.column :url, :string, :limit => 256, :null => false
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :sds_curnits
  end
end
