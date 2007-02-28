class Offering < ActiveRecord::Base
  
  set_table_name "sds_offerings"
  
  validates_presence_of :curnit_id, :jnlp_id, :name
  
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_many :errorbundles
    
end
