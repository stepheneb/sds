class MoreCurnitAttributes < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :uuid, :string, :limit => 36
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :root_pod_uuid, :string, :limit => 36
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :title, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :uuid
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :root_pod_uuid
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :title
  end
end
