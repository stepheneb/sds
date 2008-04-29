# == Schema Information
# Schema version: 58
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

require 'open-uri'

class Jnlp < ActiveRecord::Base  
  set_table_name "sds_jnlps"

  belongs_to :portal
  belongs_to :config_version
  has_many :offerings
  has_many :offerings, :order => "created_at DESC"

  before_validation :process_jnlp
  validates_presence_of :name, :url
  
  def validate 
    unless body_xml
      errors.add("jnlp body: external resource: #{url} not well-formed xml.") 
    end
  end

  def process_jnlp
    self.url.strip
    get_body
    get_last_modified
  end
  
  # see: http://github.com/mislav/will_paginate/wikis/simple-search
  def self.search(search, page, portal)
    paginate :per_page => 20, :page => page,
             :conditions => ['name like ? and portal_id = ?',"%#{search}%", portal.id], :order => 'created_at DESC'
  end

  def get_body
    if self.always_update || self.body.blank?      
      begin
        open(url) do |f|
          self.body = f.read
          self.last_modified = f.last_modified
          self.filename = File.basename(self.url)
        end
      rescue SocketError, OpenURI::HTTPError, OpenSSL::SSL::SSLError => e
        if RAILS_ENV == 'production'
          additional_info = ''
        else
          additional_info = "\n#{e.message}\n\n#{e.backtrace.join("\n")}"
        end
        raise "There was a problem saving the jnlp to the filesystem\n#{additional_info}"
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

  def body_xml
    begin
      if USE_LIBXML
        XML::Parser.string(self.body).parse.root
      else
        require "rexml/document"
        REXML::Document.new(self.body).root
      end
    rescue XML::Parser::ParseError
      nil
    end
  end

  # Jnlp.find(:all).each {|j| print "#{j.id}: "; begin j.save! rescue print "error, " ensure puts "#{j.name}" end }; nil
  #  4: error: basic-emf-post
  #  5: error: basic-emf
  #  6: error: pedagogica-emf
  #  7: error: pedagogica-emf-snapshot
  #  9: error: pedagogica-emf

end
