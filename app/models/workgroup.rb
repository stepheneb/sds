class Workgroup < ActiveRecord::Base
  set_table_name "sds_workgroups"
  belongs_to :portal
  belongs_to :offering
  has_and_belongs_to_many :users
end
