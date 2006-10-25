class Pod < ActiveRecord::Base
  set_table_name "sds_pods"
  belongs_to :curnit
  has_many :socks
end
