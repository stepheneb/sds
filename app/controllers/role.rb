class Role < ActiveRecord::Base
  set_table_name "sds_roles"
  
  has_and_belongs_to_many :users, options = {:join_table => "sds_roles_users"}

end
