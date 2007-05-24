# == Schema Information
# Schema version: 58
#
# Table name: sds_workgroup_memberships
#
#  id           :integer(11)   not null, primary key
#  sail_user_id :integer(11)   
#  workgroup_id :integer(11)   default(0), not null
#  version      :integer(11)   default(0), not null
#

class WorkgroupMembership < ActiveRecord::Base

  set_table_name "sds_workgroup_memberships"

  belongs_to :workgroup
  belongs_to :sail_user
  
  def self.find_all_in_workgroup(wid)
    version = Workgroup.find(wid).version
    WorkgroupMembership.find(:all, :conditions => ["workgroup_id = :wid and version = :version", {:wid => wid, :version => version}])
  end
  
  # because this is a associational join table the normal object is
  # a collection of workgroup_memberships in an array, this is a class
  # method that renders the default xml representation for a wgm_array
  def self.wg_array_to_xml(wgm_array)
    if wgm_array.size > 0
      wgm_array.to_xml(:except => [:id, :workgroup_id, :version])
    else
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<workgroup-memberships>\n</workgroup-memberships>"
    end
  end
  
end
