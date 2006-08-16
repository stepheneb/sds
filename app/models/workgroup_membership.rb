class WorkgroupMembership < ActiveRecord::Base

  set_table_name "sds_workgroup_memberships"

  belongs_to :workgroup
  belongs_to :user
  
  def self.find_all_in_workgroup(wid)
    version = Workgroup.find(wid).version
    WorkgroupMembership.find(:all, :conditions => ["workgroup_id = :wid and version = :version", {:wid => wid, :version => version}])
  end
  
end
