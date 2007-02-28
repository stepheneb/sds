class MoreCurnitAttributes < ActiveRecord::Migration
  def self.up
    add_column :sds_curnits, :uuid, :string, :limit => 36
    add_column :sds_curnits, :root_pod_uuid, :string, :limit => 36
    add_column :sds_curnits, :title, :string
  end

  def self.down
    remove_column :sds_curnits, :uuid
    remove_column :sds_curnits, :root_pod_uuid
    remove_column :sds_curnits, :title
  end
end
