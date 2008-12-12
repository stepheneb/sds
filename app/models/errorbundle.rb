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


  belongs_to :offering
  
  validates_presence_of :name
  
  def after_create
    if new_bundle = REXML::Document.new(self.data).root
      if new_bundle.name == "ESessionBundle"
        # Error bundles aren't quite in the correct format
        # We need to:
        #  1) remove the initial XML header (done by creating a REXML::Document)
        #  2) remove the attribute 'xmi:version="2.0" from the root element
        new_bundle.delete_attribute("version")
        #  3) rename the root element from sailuserdata:ESessionBundle to sessionBundles
        new_bundle.name = "sessionBundles"
        #  4) process the bundle so it gets included in the bundles tables
        # We need to extract workgroup id from the url in <sdsReturnAddresses>
        # format of the URL is: http://server/server_folder/#portal_id#/offering/#offering_id#/bundle/#workgroup_id#/#workgroup_version#
        elements = new_bundle.elements.to_a('//sdsReturnAddresses')
        if elements.length > 0
          matches = elements[0].get_text.to_s.match(/(\d+)\/(\d+)$/)
          b = Bundle.new(:content => new_bundle.to_s, :workgroup_id => matches[1], :workgroup_version => matches[2])
          b.save!
        end
      end
    end
  end

  def uploaded_data=(uploaded_data) 
    self.name = base_part_of(uploaded_data.original_filename) 
    self.content_type = uploaded_data.content_type.chomp 
    self.data = uploaded_data.read 
  end 

  def base_part_of(file_name) 
    File.basename(file_name).gsub(/[^\w._-]/, '') 
  end 
 
end
