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
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        head = Net::HTTP.start(uri.host, uri.port) {|http| http.head(uri.path, 'User-Agent' => '')}
        if head.class == Net::HTTPOK
          Time::httpdate(head['Last-Modified'])
        else
          'resource not available'
        end
      end
    rescue SocketError
      "network unavailable"
    end
  end
 
end
