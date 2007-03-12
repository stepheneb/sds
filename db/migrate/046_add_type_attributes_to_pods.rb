class AddTypeAttributesToPods < ActiveRecord::Migration
  def self.up
    add_column :sds_pods, :mime_type, :string
    add_column :sds_pods, :encoding, :string
    add_column :sds_pods, :pas_type, :string
    add_column :sds_pods, :extension, :string   
    remove_column :sds_socks, :mime_type
    remove_column :sds_socks, :encoding 
    remove_column :sds_socks, :pas_type 
    remove_column :sds_socks, :extension  
  end

  def self.down
    add_column :sds_socks, :mime_type, :string
    add_column :sds_socks, :encoding, :string
    add_column :sds_socks, :pas_type, :string
    add_column :sds_socks, :extension, :string   
    remove_column :sds_pods, :mime_type
    remove_column :sds_pods, :encoding 
    remove_column :sds_pods, :pas_type 
    remove_column :sds_pods, :extension  
  end
end
