class Curnit < ActiveRecord::Base
  set_table_name "sds_curnits"
  belongs_to :portal
  has_many :offerings
  has_many :pods
end
