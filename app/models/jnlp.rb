class Jnlp < ActiveRecord::Base
  require 'net/http'
  
  set_table_name "sds_jnlps"
  
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings

  def self.find_all_in_portal(pid)
    Jnlp.find(:all, :conditions => ["portal_id = ?", pid])
  end
  
  def get_jnlp
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      jnlp_body = http.get(uri.path, 'User-Agent' => '').body
    end
  end

  def get_jnlp_last_modified
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      jnlp_head = http.head(uri.path, 'User-Agent' => '')
      Time::httpdate(jnlp_head['Last-Modified'])
    end
  end
  
end
  