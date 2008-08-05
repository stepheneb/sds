class PasFinding < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}pas_findings"
  
  belongs_to :pas_model_activity_dataset
end
