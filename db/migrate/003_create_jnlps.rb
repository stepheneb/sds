class CreateJnlps < ActiveRecord::Migration
  def self.up
    create_table :sds_jnlps do |t|
      t.column :portal_id, :integer
      t.column :name, :string, :limit => 60, :null => false
      t.column :url, :string, :limit => 120, :null => false
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table :sds_jnlps
  end
end
