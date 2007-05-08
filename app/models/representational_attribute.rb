# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_representational_attributes
#
#  id                       :integer(11)   not null, primary key
#  representational_type_id :integer(11)   
#  value                    :string(255)   
#

class RepresentationalAttribute < ActiveRecord::Base
  set_table_name "sds_pas_representational_attributes"
  belongs_to :representational_type
  has_many :representational_value
  
  validates_presence_of :representational_type 
  
end
