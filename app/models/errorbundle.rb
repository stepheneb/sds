class Errorbundle < ActiveRecord::Base

  set_table_name "sds_errorbundles"
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
