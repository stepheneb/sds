class Curnit < ActiveRecord::Base
  require 'net/http'

  set_table_name "sds_curnits"
  
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings
  has_many :pods

  def self.find_all_in_portal(pid)
    Curnit.find(:all, :order => "created_at DESC", :conditions => ["portal_id = ?", pid])
  end
  
  def get_curnit_last_modified
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      curnit_head = http.head(uri.path, 'User-Agent' => '')
      Time::httpdate(curnit_head['Last-Modified'])
    end
  end
 
end
