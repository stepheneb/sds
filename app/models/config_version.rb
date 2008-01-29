class ConfigVersion < ActiveRecord::Base
  set_table_name "sds_config_versions"
  
  has_many :jnlp
end
