class User < ActiveRecord::Base
  
  set_table_name "sds_users"

  validates_presence_of :portal_id, :portal_token, :first_name, :last_name
  validates_uniqueness_of :portal_token, :scope => :portal_id

  belongs_to :portal
  has_and_belongs_to_many :offerings, options = { :join_table => 'sds_offerings_users'}
  has_many :workgroup_memberships
  has_many :workgroups, :through => :workgroup_memberships
  
  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUID.timestamp_create().to_s
  end
  
  def self.find_all_in_portal(pid)
    User.find(:all, :conditions => ["portal_id = ?", pid], :order => "last_name")
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def identifier
    "#{name}, #{portal_token}"
  end
  
  include ToXml # module in lib/to_xml, customizes class_instance.to_xml
  
end
