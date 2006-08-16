class Bundle < ActiveRecord::Base
  set_table_name "sds_bundles"
  belongs_to :offering
  belongs_to :workgroup
  has_many :socks
  has_many :rims
  
  def self.find_by_offering_and_workgroup(offering, workgroup)
    Bundle.find(:all, :conditions => ["offering_id = :offering and workgroup_id = :workgroup", {:offering => offering, :workgroup => workgroup}])
  end
  
end
