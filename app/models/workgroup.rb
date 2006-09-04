class Workgroup < ActiveRecord::Base
  
  set_table_name "sds_workgroups"

  validates_presence_of :portal_id, :offering_id, :portal_token, :name
  validates_uniqueness_of :portal_token, :scope => :portal_id

  belongs_to :portal
  belongs_to :offering
  has_many :workgroup_memberships
  has_many :users, :through => :workgroup_memberships do
    def version(version) 
      find :all, :conditions => ['version = ?', version] 
    end
  end
  # this creates the following possible search
  # members = workgroup.users.version(1)

  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUID.timestamp_create().to_s
  end

  before_destroy :delete_workgroup_memberships
  
  def delete_workgroup_memberships
    WorkgroupMembership.delete_all(["workgroup_id = ?", self.id])
  end
  
  def self.find_all_in_portal(pid)
    Workgroup.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
  include ToXml # module in lib/to_xml, customizes class_instance.to_xml

end
