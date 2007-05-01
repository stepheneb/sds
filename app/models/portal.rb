# == Schema Information
# Schema version: 50
#
# Table name: sds_portals
#
#  id                 :integer(11)   not null, primary key
#  name               :string(255)   default(""), not null
#  use_authentication :boolean(1)    
#  auth_username      :string(255)   
#  auth_password      :string(255)   
#  created_at         :datetime      
#  updated_at         :datetime      
#  title              :string(255)   
#  vendor             :string(255)   
#  home_page_url      :string(255)   
#  description        :string(255)   
#  image_url          :string(255)   
#

# require 'conversions.rb'

class Portal < ActiveRecord::Base
  set_table_name "sds_portals"
  validates_presence_of :name, :title, :vendor, :home_page_url, :image_url

  has_many :curnits, :order => "created_at DESC"
  has_many :jnlps, :order => "created_at DESC"
  has_many :offerings, :order => "created_at DESC"
  has_many :sail_users, :order => "created_at DESC"
  has_many :workgroups, :order => "created_at DESC"
  has_many :portal_urls

end

