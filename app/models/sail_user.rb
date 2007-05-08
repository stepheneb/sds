# == Schema Information
# Schema version: 58
#
# Table name: sds_sail_users
#
#  id         :integer(11)   not null, primary key
#  portal_id  :integer(11)   
#  first_name :string(60)    default(""), not null
#  last_name  :string(60)    default(""), not null
#  uuid       :string(36)    default(""), not null
#  created_at :datetime      
#  updated_at :datetime      
#

class SailUser < ActiveRecord::Base
  
  set_table_name "sds_sail_users"

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
