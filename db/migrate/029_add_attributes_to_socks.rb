class AddAttributesToSocks < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}socks", :mime_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :encoding, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :pas_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :extension, :string
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :mime_type
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :encoding
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :pas_type
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :extension
  end
end
