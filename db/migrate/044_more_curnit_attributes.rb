class MoreCurnitAttributes < ActiveRecord::Migration
  def self.up
    add_column "curnits", :uuid, :string, :limit => 36
    add_column "curnits", :root_pod_uuid, :string, :limit => 36
    add_column "curnits", :title, :string
  end

  def self.down
    remove_column "curnits", :uuid
    remove_column "curnits", :root_pod_uuid
    remove_column "curnits", :title
  end
end
