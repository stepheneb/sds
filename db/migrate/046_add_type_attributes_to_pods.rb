class AddTypeAttributesToPods < ActiveRecord::Migration
  def self.up
    add_column "pods", :mime_type, :string
    add_column "pods", :encoding, :string
    add_column "pods", :pas_type, :string
    add_column "pods", :extension, :string   
    remove_column "socks", :mime_type
    remove_column "socks", :encoding 
    remove_column "socks", :pas_type 
    remove_column "socks", :extension  
  end

  def self.down
    add_column "socks", :mime_type, :string
    add_column "socks", :encoding, :string
    add_column "socks", :pas_type, :string
    add_column "socks", :extension, :string   
    remove_column "pods", :mime_type
    remove_column "pods", :encoding 
    remove_column "pods", :pas_type 
    remove_column "pods", :extension  
  end
end
