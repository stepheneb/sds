require 'conversions.rb'

class Portal < ActiveRecord::Base
  set_table_name "sds_portals"
  validates_presence_of :name

  has_many :curnits
  has_many :jnlps
  has_many :offerings
  has_many :users
  has_many :workgroups
  has_many :portal_urls
end

