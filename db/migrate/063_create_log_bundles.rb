class CreateLogBundles < ActiveRecord::Migration
  def self.up
    create_table :sds_log_bundles do |t|
      t.column :bundle_id, :integer
      t.column :workgroup_id, :integer
      t.column :portal_id, :integer
      t.column :offering_id, :integer
      t.column :sail_session_uuid, :string, :limit => 36
      t.column :sail_curnit_uuid, :string, :limit => 3
      t.column :content, :text, :limit => 16777215
      t.timestamps
    end
  end

  def self.down
    drop_table :sds_log_bundles
  end
end
