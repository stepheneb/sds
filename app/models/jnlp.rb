class Jnlp < ActiveRecord::Base  
  set_table_name "sds_jnlps"
  
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings

  def self.find_all_in_portal(pid)
    Jnlp.find(:all, :order => "created_at DESC", :conditions => ["portal_id = ?", pid])
  end
  
  def get_jnlp
    uri = URI.parse(url)
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        jnlp_body = http.get(uri.path, 'User-Agent' => '').body
      end
    rescue SocketError
      nil
    end
  end

  def get_jnlp_last_modified
    uri = URI.parse(url)
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        jnlp_head = http.head(uri.path, 'User-Agent' => '')
        Time::httpdate(jnlp_head['Last-Modified'])
      end
    rescue SocketError
      "network unavailable"
    end
  end
  
end
  