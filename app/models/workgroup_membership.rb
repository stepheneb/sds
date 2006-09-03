class WorkgroupMembership < ActiveRecord::Base

  set_table_name "sds_workgroup_memberships"

  belongs_to :workgroup
  belongs_to :user
  
  def self.find_all_in_workgroup(wid)
    version = Workgroup.find(wid).version
    WorkgroupMembership.find(:all, :conditions => ["workgroup_id = :wid and version = :version", {:wid => wid, :version => version}])
  end
  
  # because this is a associational join table the normal object is
  # a collection of workgroup_memberships in an array, this is a class
  # method that renders the default xml representation for a wg_array
  def self.wg_array_to_xml(wg_array)
    wg_array.to_xml(:except => [:id, :workgroup_id, :version])
  end
  
end
