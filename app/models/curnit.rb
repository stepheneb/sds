class Curnit < ActiveRecord::Base

  set_table_name "sds_curnits"
  
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings
  has_many :pods

  def self.find_all_in_portal(pid)
    Curnit.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
#  include ToXml # module in lib/to_xml, customizes class_instance.to_xml
 
#  def to_xml
#    super(:except => ['created_at', 'updated_at'])
#  end
 
end
