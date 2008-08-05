# == Schema Information
# Schema version: 58
#
# Table name: sds_pas_model_activity_modelruns
#
#  id                        :integer(11)   not null, primary key
#  model_activity_dataset_id :integer(11)   
#  start_time                :float         
#  end_time                  :float         
#

class ModelActivityModelrun < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}pas_model_activity_modelruns"
  belongs_to :model_activity_dataset
  has_many :computational_input_value, :dependent => :destroy
  has_many :representational_value, :dependent => :destroy
  
  validates_presence_of :model_activity_dataset 
  
end
