class ChangeSockMsOffsetToInteger < ActiveRecord::Migration
  def self.up
    change_column "#{RAILS_DATABASE_PREFIX}socks", :ms_offset, :integer
  end

  def self.down
    change_column "#{RAILS_DATABASE_PREFIX}socks", :ms_offset, :float
  end
end
