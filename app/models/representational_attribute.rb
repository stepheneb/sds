class RepresentationalAttribute < ActiveRecord::Base
  set_table_name "sds_pas_representational_attributes"
  belongs_to :representational_type
  has_many :representational_value
  
  validates_presence_of :representational_type 
  
end
