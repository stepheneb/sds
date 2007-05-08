# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_representational_types
#
#  id                        :integer(11)   not null, primary key
#  model_activity_dataset_id :integer(11)   
#  name                      :string(255)   
#

class RepresentationalType < ActiveRecord::Base
  set_table_name "sds_pas_representational_types"
  belongs_to :model_activity_dataset
  has_many :representational_attribute
  
  validates_presence_of :model_activity_dataset
  
end
