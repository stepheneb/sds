# == Schema Information
# Schema version: 58
#
# Table name: sds_errorbundles
#
#  id           :integer(11)   not null, primary key
#  offering_id  :integer(11)   
#  comment      :string(255)   
#  name         :string(255)   
#  content_type :string(255)   
#  data         :binary        
#  created_at   :datetime      
#  ip_address   :string(255)   
#

class Errorbundle < ActiveRecord::Base

  set_table_name "#{RAILS_DATABASE_PREFIX}errorbundles"
  belongs_to :offering
  
  validates_presence_of :name

  def uploaded_data=(uploaded_data) 
    self.name = base_part_of(uploaded_data.original_filename) 
    self.content_type = uploaded_data.content_type.chomp 
    self.data = uploaded_data.read 
  end 

  def base_part_of(file_name) 
    File.basename(file_name).gsub(/[^\w._-]/, '') 
  end 
 
end
