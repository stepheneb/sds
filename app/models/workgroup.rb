class Workgroup < ActiveRecord::Base  
  set_table_name "sds_workgroups"
  belongs_to :portal
  belongs_to :offering
  has_many :workgroup_memberships
  has_many :bundles

  validates_presence_of :offering, :name
  validates_associated :offering
  
  # this creates the following possible search
  # members = workgroup.users.version(1)
  has_many :sail_users, :through => :workgroup_memberships do
    def version(version)
      find :all, :conditions => ['version = ?', version] 
    end
  end

  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUID.timestamp_create().to_s
  end

  before_destroy :delete_workgroup_memberships
  
  def delete_workgroup_memberships
    WorkgroupMembership.delete_all(["workgroup_id = ?", self.id])
  end
  
  def bundles(sort_direction='DESC')
    Bundle.find(:all, :order => "created_at #{sort_direction}", :conditions => ['workgroup_id = ?', id])
  end
  
  def members
    self.sail_users.version(self.version)
  end
  
  def member_names
    self.members.collect {|m| m.name}.join(', ')
  end
end
