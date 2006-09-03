class Curnit < ActiveRecord::Base

  set_table_name "sds_curnits"
  
  validates_presence_of :portal_id, :name, :url
#  validates_uniqueness_of :portal_token, :scope => :portal_id
  
  belongs_to :portal
  has_many :offerings
  has_many :pods

  def self.find_all_in_portal(pid)
    Curnit.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
  include FromXml # module in lib/from_xml, customizes class_instance.to_xml
  
end
