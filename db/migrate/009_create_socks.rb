class CreateSocks < ActiveRecord::Migration
  def self.up
    create_table :sds_socks do |t|
      t.column :offering_id, :integer
      t.column :workgroup_id, :integer
      t.column :bundle_id, :integer
      t.column :rim_id, :integer
      t.column :created_at, :timestamp
      t.column :ms_offset, :float
      t.column :value, :text
      
    end
  end

  def self.down
    drop_table :sds_socks
  end
end
