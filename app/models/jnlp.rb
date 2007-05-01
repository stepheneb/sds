# == Schema Information
# Schema version: 50
#
# Table name: sds_jnlps
#
#  id            :integer(11)   not null, primary key
#  portal_id     :integer(11)   
#  name          :string(60)    default(""), not null
#  url           :string(256)   
#  created_at    :datetime      
#  updated_at    :datetime      
#  body          :text          
#  always_update :boolean(1)    
#  last_modified :datetime      
#  filename      :string(255)   
#

class Jnlp < ActiveRecord::Base  
  set_table_name "sds_jnlps"
    
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings
  has_many :offerings, :order => "created_at DESC"
  
  before_save { |j| j.url.strip! }
  before_save :get_body
  before_save :get_last_modified
  
  def get_body
    if self.always_update || self.body.blank?      
      begin
        open(url) do |f|
          self.body = f.read
          self.last_modified = f.last_modified
          self.filename = File.basename(self.url)
        end
      rescue SocketError # getaddrinfo?
      end
    end
    self.body
  end
  
  def get_last_modified
    if self.always_update || self.body.blank?
      uri = URI.parse(url)
      begin
        Net::HTTP.start(uri.host, uri.port) do |http|
          head = Net::HTTP.start(uri.host, uri.port) {|http| http.head(uri.path, 'User-Agent' => '')}
          if head.class == Net::HTTPOK
            self.last_modified=Time::httpdate(head['Last-Modified'])
          else
            'jnlp not available'
          end
        end
      rescue SocketError
        "network unavailable"
      end
    end
  end
  
  protected
  
# Jnlp.find_all.each {|j| print "#{j.id}: "; begin j.save! rescue print "error, " ensure puts "#{j.name}" end }; nil
#  4: error: basic-emf-post
#  5: error: basic-emf
#  6: error: pedagogica-emf
#  7: error: pedagogica-emf-snapshot
#  9: error: pedagogica-emf

end
  
