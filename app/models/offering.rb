# == Schema Information
# Schema version: 50
#
# Table name: sds_offerings
#
#  id             :integer(11)   not null, primary key
#  portal_id      :integer(11)   
#  curnit_id      :integer(11)   
#  jnlp_id        :integer(11)   
#  name           :string(60)    default(""), not null
#  created_at     :datetime      
#  updated_at     :datetime      
#  open_offering  :datetime      
#  close_offering :datetime      
#

class Offering < ActiveRecord::Base
  
  set_table_name "sds_offerings"
  
  validates_presence_of :curnit_id, :jnlp_id, :name
  
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_many :errorbundles
    
end
