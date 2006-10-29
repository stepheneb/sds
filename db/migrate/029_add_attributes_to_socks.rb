class AddAttributesToSocks < ActiveRecord::Migration
  def self.up
    add_column :sds_socks, :mime_type, :string
    add_column :sds_socks, :encoding, :string
    add_column :sds_socks, :pas_type, :string
    add_column :sds_socks, :extension, :string
  end

  def self.down
    remove_column :sds_socks, :mime_type
    remove_column :sds_socks, :encoding
    remove_column :sds_socks, :pas_type
    remove_column :sds_socks, :extension
  end
end
