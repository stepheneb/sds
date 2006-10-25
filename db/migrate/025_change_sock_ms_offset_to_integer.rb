class ChangeSockMsOffsetToInteger < ActiveRecord::Migration
  def self.up
    change_column :sds_socks, :ms_offset, :integer
  end

  def self.down
    change_column :sds_socks, :ms_offset, :float
  end
end
