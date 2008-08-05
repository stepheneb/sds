# == Schema Information
# Schema version: 58
#
# Table name: sds_roles
#
#  id    :integer(11)   not null, primary key
#  title :string(255)   
#

class Role < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}roles"
  
  has_and_belongs_to_many :users, options = {:join_table => "sds_roles_users"}

end
