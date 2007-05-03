class RepresentationalType < ActiveRecord::Base
  set_table_name "sds_pas_representational_types"
  belongs_to :model_activity_dataset
  has_many :representational_attribute
  
  validates_presence_of :model_activity_dataset
  
end
