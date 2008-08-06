class CreateBundles < ActiveRecord::Migration
  def self.up
    create_table "bundles" do |t|
      t.column :offering_id, :integer
      t.column :workgroup_id, :integer
      t.column :workgroup_version, :integer
      t.column :content, :text
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table "bundles"
  end
end
