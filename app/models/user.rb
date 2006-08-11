class User < ActiveRecord::Base
  set_table_name "sds_users"
  belongs_to :portal
  has_and_belongs_to_many :workgroups
  has_and_belongs_to_many :offerings
end
