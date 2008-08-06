class AddAttributesToSocks < ActiveRecord::Migration
  def self.up
    add_column "socks", :mime_type, :string
    add_column "socks", :encoding, :string
    add_column "socks", :pas_type, :string
    add_column "socks", :extension, :string
  end

  def self.down
    remove_column "socks", :mime_type
    remove_column "socks", :encoding
    remove_column "socks", :pas_type
    remove_column "socks", :extension
  end
end
