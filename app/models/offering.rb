# == Schema Information
# Schema version: 58
#
# Table name: sds_offerings
#
#  id             :integer(11)   not null, primary key
#  portal_id      :integer(11)   
#  curnit_id      :integer(11)   
#  jnlp_id        :integer(11)   
#  name           :string(60)    default(""), not null
#  created_at     :datetime      
#  updated_at     :datetime      
#  open_offering  :datetime      
#  close_offering :datetime      
#

class Offering < ActiveRecord::Base

  validates_presence_of :curnit_id, :jnlp_id, :name
  
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_many :bundles, :through => :workgroups

  has_many :socks,
    :finder_sql => "SELECT socks.* FROM socks 
    INNER JOIN bundles ON socks.bundle_id = bundles.id 
    INNER JOIN workgroups ON bundles.workgroup_id = workgroups.id 
    WHERE workgroups.offering_id = #{id}"

  has_many :pods,
    :finder_sql => "SELECT DISTINCT pods.* FROM pods
    INNER JOIN socks ON pods.id = socks.pod_id    
    INNER JOIN bundles ON socks.bundle_id = bundles.id 
    INNER JOIN workgroups ON bundles.workgroup_id = workgroups.id 
    WHERE workgroups.offering_id = #{id}"
  
  has_many :errorbundles
  has_many :offerings_attributes
  
  before_destroy :delete_offerings_attributes
  
  def delete_offerings_attributes
    attrs = OfferingsAttribute.find(:all, :conditions => "offering_id = #{self.id}")
    attrs.each do |a|
      a.destroy
    end
  end
  
  # see: http://github.com/mislav/will_paginate/wikis/simple-search
  def self.search(search, page, portal)
    paginate :per_page => 20, :page => page,
             :conditions => ['name like ? and portal_id = ?',"%#{search}%",  portal.id], :order => 'created_at DESC'
  end
  
end
