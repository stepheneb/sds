class Role < ActiveRecord::Base
  set_table_name "sds_roles"
  
  has_and_belongs_to_many :sds_users, options = {:join_table => "sds_roles_sds_users"}

end
