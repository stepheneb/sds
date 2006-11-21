class Pod < ActiveRecord::Base
  set_table_name "sds_pods"
  has_and_belongs_to_many :sds_curnits, options = {:join_table => "sds_curnits_sds_pods"}
  
  belongs_to :curnit
  has_many :socks
end
