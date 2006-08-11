class Sock < ActiveRecord::Base
  set_table_name "sds_socks"
  belongs_to :offering
  belongs_to :pod
  belongs_to :user
  belongs_to :workgroup
  belongs_to :bundle
end
