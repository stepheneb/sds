class Jnlp < ActiveRecord::Base
  
  set_table_name "sds_jnlps"
  
  validates_presence_of :portal_id, :name, :url
#  validates_uniqueness_of :portal_token, :scope => :portal_id
  
  belongs_to :portal
  has_many :offerings

  def self.find_all_in_portal(pid)
    Jnlp.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
  include ToXml # module in lib/to_xml, customizes class_instance.to_xml
  
end
  