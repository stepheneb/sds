class ChangeSockValueColumnType < ActiveRecord::Migration
  def self.up
					change_column "#{RAILS_DATABASE_PREFIX}socks", :value, :text, :limit => 16777215
  end

  def self.down
  end
end
