# == Schema Information
# Schema version: 58
#
# Table name: sds_workgroups
#
#  id          :integer(11)   not null, primary key
#  portal_id   :integer(11)   
#  offering_id :integer(11)   
#  name        :string(60)    default(""), not null
#  uuid        :string(36)    default(""), not null
#  version     :integer(11)   default(0), not null
#  created_at  :datetime      
#  updated_at  :datetime      
#

class Workgroup < ActiveRecord::Base  
  set_table_name "sds_workgroups"
#  acts_as_reportable
  belongs_to :portal
  belongs_to :offering
  has_many :workgroup_memberships
  has_many :log_bundles
  
  # see: http://weblog.jamisbuck.org/2007/1/18/activerecord-association-scoping-pitfalls
  # and http://weblog.jamisbuck.org/2006/10/18/skinny-controller-fat-model
  
  has_many :bundles do
    def asc # this is the default behavior
      @asc ||= find(:all, :order => "created_at ASC")
    end
    def desc
      @desc ||= find(:all, :order => "created_at DESC")
    end
  end

  has_many :valid_bundles, :class_name => "Bundle", :conditions => 'process_status = 1' do
    def asc # this is the default behavior
      @asc ||= find(:all, :order => "created_at ASC")
    end
    def desc
      @desc ||= find(:all, :order => "created_at DESC")
    end
  end 

  validates_presence_of :offering, :name
  validates_associated :offering
  
  # this creates the following possible search
  # members = workgroup.sail_users.version(1)
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
  
  def members
    self.sail_users.version(self.version)
  end
  
  def member_names
    self.members.collect {|m| m.name}.join(', ')
  end
  
  def master_curnitmap
    cmap = {}
    self.valid_bundles.each do |b|
      curnitmap = b.curnitmap
      if curnitmap != nil
        cmap.merge!(curnitmap){|k,old,new| old }
      end
    end
    return cmap
  end
end
