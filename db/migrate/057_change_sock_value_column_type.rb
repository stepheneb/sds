class ChangeSockValueColumnType < ActiveRecord::Migration
  def self.up
					change_column :sds_socks, :value, :text, :limit => 16777215
  end

  def self.down
  end
end
