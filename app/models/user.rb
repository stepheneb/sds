class User < ActiveRecord::Base
  
  set_table_name "sds_users"

  validates_presence_of :first_name, :last_name

  belongs_to :portal
  has_and_belongs_to_many :offerings, options = { :join_table => 'sds_offerings_users'}
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
  
  def self.find_all_in_portal(pid)
    User.find(:all, :order => "created_at DESC", :conditions => ["portal_id = ?", pid])
  end

  def self.find_all_in_offering(oid)
    User.find(:all, :order => "created_at DESC", :conditions => ["offering_id = ?", oid])
  end
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def identifier
    "#{name}"
  end
  
end
