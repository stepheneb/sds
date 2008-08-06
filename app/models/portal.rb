# == Schema Information
# Schema version: 58
#
# Table name: portals
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

  validates_presence_of :name, :title, :vendor, :home_page_url, :image_url

  has_many :curnits, :order => "created_at DESC"
  has_many :jnlps, :order => "created_at DESC"
  has_many :offerings, :order => "created_at DESC"
  has_many :sail_users, :order => "created_at DESC"
  has_many :workgroups, :order => "created_at DESC"
  has_many :portal_urls

  has_many :bundles, :finder_sql => 'SELECT bundles.* FROM bundles 
    INNER JOIN workgroups ON bundles.workgroup_id = workgroups.id 
    INNER JOIN offerings ON workgroups.offering_id = offerings.id 
    WHERE offerings.portal_id = #{id}' do
    def created_after(date)
      find_all {|b| b.created_at > date}
      # find(:all, :conditions => ['created_at > ?', date])
    end
  end
  
  # see: http://github.com/mislav/will_paginate/wikis/simple-search
  def self.search(search, page)
    paginate :per_page => 20, :page => page,
             :conditions => ['name like ?',"%#{search}%"], :order => 'created_at ASC'
  end
  
  def image_url
    if Thread.current[:request] && read_attribute(:image_url)
      u = URI.parse("#{Thread.current[:request].protocol}#{Thread.current[:request].host}:#{Thread.current[:request].port}/#{Thread.current[:request].path}")
      u.merge(read_attribute(:image_url)).to_s
    else
      read_attribute(:image_url)
    end
  end

end

