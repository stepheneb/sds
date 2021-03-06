# == Schema Information
# Schema version: 58
#
# Table name: sds_portal_urls
#
#  id        :integer(11)   not null, primary key
#  portal_id :integer(11)   
#  name      :string(60)    default(""), not null
#  url       :string(120)   default(""), not null
#

class PortalUrl < ActiveRecord::Base

  belongs_to :portal
end
