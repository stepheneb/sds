# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_representational_values
#
#  id                            :integer(11)   not null, primary key
#  model_activity_modelrun_id    :integer(11)   
#  representational_attribute_id :integer(11)   
#  time                          :float         
#

class RepresentationalValue < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}pas_representational_values"
  belongs_to :representational_attribute
  belongs_to :model_activity_modelrun
  
  validates_presence_of :representational_attribute, :model_activity_modelrun
  
end
