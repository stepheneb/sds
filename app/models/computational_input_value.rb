class ComputationalInputValue < ActiveRecord::Base
  set_table_name "sds_pas_computational_input_values"
  belongs_to :computational_input
  belongs_to :model_activity_modelrun
  
  validates_presence_of :computational_input, :model_activity_modelrun
  
end
