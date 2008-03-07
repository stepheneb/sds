class CreateOfferings < ActiveRecord::Migration
  def self.up
    create_table :sds_offerings do |t|
      t.column :portal_id, :integer
      t.column :curnit_id, :integer
      t.column :jnlp_id, :integer
      t.column :name, :string, :limit => 60
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :sds_offerings
  end
end
