# == Schema Information
# Schema version: 58
#
# Table name: sds_rims
#
#  id     :integer(11)   not null, primary key
#  pod_id :integer(11)   
#  name   :string(255)   
#

class Rim < ActiveRecord::Base

  belongs_to :pod
  has_many :socks
end
