class ComputationalInput < ActiveRecord::Base
  set_table_name "sds_pas_computational_inputs"
  belongs_to :model_activity_dataset
  has_many :computational_input_value
  
  validates_presence_of :model_activity_dataset
  
end
