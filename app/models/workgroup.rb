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
  
  # see: http://github.com/mislav/will_paginate/wikis/simple-search
  def self.search(search, page, portal)
    paginate :per_page => 20, :page => page,
             :conditions => ['name like ? and portal_id = ?',"%#{search}%", portal.id], :order => 'created_at DESC'
  end
  
  # see: http://weblog.jamisbuck.org/2007/1/18/activerecord-association-scoping-pitfalls
  # and http://weblog.jamisbuck.org/2006/10/18/skinny-controller-fat-model
  
  has_many :bundles do
    def asc # this is the default behavior
      find(:all, :order => "sail_session_modified_time ASC, created_at ASC")
    end
    def desc
      find(:all, :order => "sail_session_modified_time DESC, created_at ASC")
    end
  end

  has_many :valid_bundles, :class_name => "Bundle", :conditions => 'process_status = 1 OR process_status = 3' do
    def asc # this is the default behavior
      find(:all, :order => "sail_session_modified_time ASC, created_at ASC")
    end
    def desc
      find(:all, :order => "sail_session_modified_time DESC, created_at ASC")
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
  
  def blank_ot_learner_data
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.otrunk("id" => UUID.timestamp_create().to_s) { 
      xml.imports {
        xml.import("class" => "org.concord.otrunk.OTStateRoot")
        xml.import("class" => "org.concord.otrunk.user.OTUserObject")
        xml.import("class" => "org.concord.otrunk.user.OTReferenceMap")
      }
       xml.objects {
        xml.OTStateRoot("formatVersionString" => "1.0") {
          xml.userMap {
            userkey = self.uuid
            xml.entry("key" => userkey) {
              xml.OTReferenceMap {
                xml.user {
                 xml.OTUserObject("name" => "#{self.member_names}", "id" => userkey) 
                }
              }
            }
          }
        }
      }
    }
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
