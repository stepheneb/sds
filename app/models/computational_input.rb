# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_computational_inputs
#
#  id                        :integer(11)   not null, primary key
#  model_activity_dataset_id :integer(11)   
#  name                      :string(255)   
#  units                     :string(255)   
#  range_max                 :float         
#  range_min                 :float         
#

class ComputationalInput < ActiveRecord::Base
  set_table_name "sds_pas_computational_inputs"
  belongs_to :model_activity_dataset
  has_many :computational_input_value, :dependent => :destroy
  
  validates_presence_of :model_activity_dataset
  
end
