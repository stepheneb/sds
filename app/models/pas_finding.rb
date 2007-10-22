class PasFinding < ActiveRecord::Base
  set_table_name "sds_pas_findings"
  
  belongs_to :pas_model_activity_dataset
end
