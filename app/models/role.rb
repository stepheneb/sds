# == Schema Information
# Schema version: 50
#
# Table name: sds_roles
#
#  id    :integer(11)   not null, primary key
#  title :string(255)   
#

class Role < ActiveRecord::Base
  set_table_name "sds_roles"
  
  has_and_belongs_to_many :users, options = {:join_table => "sds_roles_users"}

end
