class Bundle < ActiveRecord::Base
  set_table_name "sds_bundles"
  belongs_to :portal
  belongs_to :offering
  belongs_to :user
  belongs_to :workgroup
  has_many :socks
  has_many :rims
end
