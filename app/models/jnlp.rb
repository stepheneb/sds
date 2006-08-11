class Jnlp < ActiveRecord::Base
  set_table_name "sds_jnlps"
  belongs_to :portal
  has_many :offerings
end
  