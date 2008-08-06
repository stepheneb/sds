class CreateSocks < ActiveRecord::Migration
  def self.up
    create_table "socks" do |t|
      t.column :offering_id, :integer
      t.column :workgroup_id, :integer
      t.column :session_id, :integer
      t.column :rim_id, :integer
      t.column :created_at, :timestamp
      t.column :ms_offset, :float
      t.column :value, :text
      
    end
  end

  def self.down
    drop_table "socks"
  end
end
