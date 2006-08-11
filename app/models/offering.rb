class Offering < ActiveRecord::Base
  set_table_name "sds_offerings"
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_and_belongs_to_many :users
end
