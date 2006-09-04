class Offering < ActiveRecord::Base
  
  set_table_name "sds_offerings"
  
  validates_presence_of :portal_id, :curnit_id, :jnlp_id, :name
  validates_uniqueness_of :portal_token, :scope => :portal_id
  
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_and_belongs_to_many :users, options = { :join_table => 'sds_offerings_users'}

  def self.find_all_in_portal(pid)
    Offering.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
  include ToXml # module in lib/to_xml, customizes class_instance.to_xml
  
end
