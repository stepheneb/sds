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

