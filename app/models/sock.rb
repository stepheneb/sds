class Sock < ActiveRecord::Base
  set_table_name "sds_socks"
  belongs_to :bundle
  belongs_to :pod
end
