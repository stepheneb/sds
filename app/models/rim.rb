class Rim < ActiveRecord::Base
  set_table_name "sds_rims"
  belongs_to :pod
  has_many :socks
end
