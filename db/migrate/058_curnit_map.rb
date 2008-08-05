class CurnitMap < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}curnit_maps" do |t|
      t.column :parent_id, :integer
      t.column :position, :integer
      t.column :pod_uuid, :string, :limit => 36
      t.column :title, :string
      t.column :number, :integer
      t.column :classname, :string
      t.column :type, :string
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}curnit_maps"
  end
end
