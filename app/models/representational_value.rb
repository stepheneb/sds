class RepresentationalValue < ActiveRecord::Base
  set_table_name "sds_pas_representational_values"
  belongs_to :representational_attribute
  belongs_to :model_activity_modelrun
  
  validates_presence_of :representational_attribute, :model_activity_modelrun
  
end
