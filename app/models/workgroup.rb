class Workgroup < ActiveRecord::Base
  
  set_table_name "sds_workgroups"

  validates_presence_of :offering_id, :name

  belongs_to :portal
  belongs_to :offering
  has_many :workgroup_memberships

  # this creates the following possible search
  # members = workgroup.users.version(1)
  has_many :users, :through => :workgroup_memberships do
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
  
  def self.find_all_in_portal(pid)
    Workgroup.find(:all, :order => "created_at DESC", :conditions => ["portal_id = ?", pid])
  end

  def self.find_all_in_offering(oid)
    Workgroup.find(:all, :order => "created_at DESC", :conditions => ["offering_id = ?", oid])
  end
  
  def bundles
    Bundle.find(:all, :order => "created_at DESC", :conditions => ['workgroup_id = ?', id])
  end

end
