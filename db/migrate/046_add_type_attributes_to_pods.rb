class AddTypeAttributesToPods < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}pods", :mime_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}pods", :encoding, :string
    add_column "#{RAILS_DATABASE_PREFIX}pods", :pas_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}pods", :extension, :string   
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :mime_type
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :encoding 
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :pas_type 
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :extension  
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}socks", :mime_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :encoding, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :pas_type, :string
    add_column "#{RAILS_DATABASE_PREFIX}socks", :extension, :string   
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :mime_type
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :encoding 
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :pas_type 
    remove_column "#{RAILS_DATABASE_PREFIX}pods", :extension  
  end
end
