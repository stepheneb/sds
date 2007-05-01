# == Schema Information
# Schema version: 50
#
# Table name: sds_bundle_contents
#
#  id      :integer(11)   not null, primary key
#  content :text          
#

class BundleContent < ActiveRecord::Base
  set_table_name "sds_bundle_contents"
  has_one :bundle
end
