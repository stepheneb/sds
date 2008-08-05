# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_computational_input_values
#
#  id                         :integer(11)   not null, primary key
#  model_activity_modelrun_id :integer(11)   
#  computational_input_id     :integer(11)   
#  value                      :float         
#  time                       :float         
#

class ComputationalInputValue < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}pas_computational_input_values"
  belongs_to :computational_input
  belongs_to :model_activity_modelrun
  
  validates_presence_of :computational_input, :model_activity_modelrun
  
end
