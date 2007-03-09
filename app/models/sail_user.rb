class User < ActiveRecord::Base
  
  set_table_name "sds_users"

  validates_presence_of :first_name, :last_name

  belongs_to :portal
  has_many :workgroup_memberships
  
  # this creates the following possible search
  # workgroups = user.workgroups?
  has_many :workgroups, :through => :workgroup_memberships

  def workgroup?
    self.workgroups.length != 0
  end
  
  def workgroup
    self.workgroups.sort {|a,b| a.id <=> b.id}[0]
  end
  
  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUID.timestamp_create().to_s
  end

  def name
    "#{first_name} #{last_name}"
  end
  
  def identifier
    "#{name}"
  end
  
end