class ModelActivityModelrun < ActiveRecord::Base
  set_table_name "sds_pas_model_activity_modelruns"
  belongs_to :model_activity_dataset
  has_many :computational_input_value
  has_many :representational_value
  
  validates_presence_of :model_activity_dataset 
  
end
