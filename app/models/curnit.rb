# == Schema Information
# Schema version: 58
#
# Table name: sds_curnits
#
#  id                :integer(11)   not null, primary key
#  portal_id         :integer(11)   
#  name              :string(60)    default(""), not null
#  url               :string(256)   
#  created_at        :datetime      
#  updated_at        :datetime      
#  pas_map           :text          
#  always_update     :boolean(1)    
#  jar_digest        :string(255)   
#  jar_last_modified :datetime      
#  uuid              :string(36)    
#  root_pod_uuid     :string(36)    
#  title             :string(255)   
#

class Curnit < ActiveRecord::Base
  require 'net/http'
  set_table_name "sds_curnits"

  attr_reader :podxml_cache, :test
  
  validates_presence_of :name, :url
  validate :validate_always_update
  belongs_to :portal
  has_many :offerings, :order => "created_at DESC"
  has_many :pods
  has_one :curnit_map
  
  before_save { |c| c.url.strip! }
  before_update :check_for_jar # run this when saving an existing object
  after_create :check_for_jar_create # need an id for this, so in creation run it after_create
  
  require 'fileutils'
  require 'open-uri'
  require 'zip/zipfilesystem'
    
  def after_initialize
    @podxml_cache = Hash.new
  end

	def url
    if Thread.current[:request] && read_attribute(:url)
      u = URI.parse("#{Thread.current[:request].protocol}#{Thread.current[:request].host}:#{Thread.current[:request].port}/#{Thread.current[:request].path}")
      u.merge(read_attribute(:url)).to_s
    else
      read_attribute(:url)
    end
  end
	
  # look for the pod in this curnit: 
  # look in this order
  # 1) memory cache
  # 2) sds file system cache
  # returning an REXMLor LIBXML object with the 
  # xmlencoded form of the pod if found
  # and '' (empty string) if not found
  def find_podxml(uuid)
    podpath = self.path + 'POD_' + uuid + '.xml'
    case
    when @podxml_cache.has_key?(uuid)
      @podxml_cache[uuid]
    when File.exists?(podpath)
      px = File.read(podpath)
      if USE_LIBXML
        @podxml_cache[uuid] = XML::Parser.string(px).parse.root
      else # use REXML
        @podxml_cache[uuid] = REXML::Document.new(px)
      end
    else
      ''
    end
  end

  # look for the pod in this curnit
  # returning an REXMLor LIBXML object with the 
  # xmlencoded form of the pod if found
  # and nil if not found
  def find_podxml_in_jar(pod_id)
    uuid = if pod_id.kind_of?(String) && pod_id.length == 36
      pod_id
    else
      Pod.find(pod_id).uuid
    end
    unless uuid.blank?
      Zip::ZipFile.open(self.jar_path, Zip::ZipFile::CREATE) do |jar|
        podxml = jar.file.read("POD_#{uuid}.xml")
        if USE_LIBXML
          XML::Parser.string(podxml).parse.root
        else # use REXML
          REXML::Document.new(podxml)
        end
      end
    end
  end
  
  # valid values for always_update attribute are either
  # true, false, or not specified (which is a value of nil)
  # default will be true if not specified
  # returns: true when attribute valid
  # returns false otherwise
  def validate_always_update
    # debugger
    if self.always_update == nil
      self.always_update = true
    end
  end
  
  def check_for_jar_create
    self.update_jar
    self.save
  end

  # if no curnit jar exists then get curnit jar and set jar_digest and jar_last_modified
  # else if always_update then if external curnit last_modified newer than jar_last_modified then update_jar
  def check_for_jar
    if self.jar_last_modified.blank? || self.always_update || self.local_jar_empty?
      self.update_jar
    end
  end

  def local_jar_empty?
    !File.exists?(self.jar_path)
  end
  
  def filename
    File.basename(self.url)
  end
  
  # Returns full path to jar without the base filename of the jar
  #
  # deal with strange issue of chroot at railsapp/ in development
  # mode and railsapp/public/ in production on the server
  def path  
    "#{SdsCache.instance.path}#{self.portal.id}/curnits/#{self.id}/"
  end
  
  # Returns full path to jar on filesystem
  #
  def jar_path
    "#{self.path}#{self.filename}"
  end
  
  # Returns partial path to jar rooted at public/ dir
  #
  def jar_public_path
    self.jar_path[/(\/public\/)(.*)/, 2]
  end

  # a coding of time to a generic filesystem compatible string
  # >> c.jar_last_modified.iso8601.gsub(/\W/, '_')
  # => "2007_02_05T16_27_40_05_00"
  # a coding of a descriptive string to
  # a generic filesystem compatible string
  # self.name.strip.downcase.gsub(/\W+/, '_').gsub(/^_+|_+$/, '')
  # these regex's aren't used anymore ...
  # but they seemed too nice to just delete

  def update_jar
    if self.jar_last_modified.blank? || (self.jar_last_modified < self.get_last_modified) || ! File.exists?(self.path)
      begin
        url_string = self.url
        open(url_string) do |urlfile|
          if File.exists?(self.path)
            FileUtils.rmtree(Dir.glob(self.path + '*'))
          else
            FileUtils.mkdir_p(self.path)
          end
          File.open(self.jar_path, 'wb') {|jar| jar.write(urlfile.read) }
          Zip::ZipFile.foreach("#{self.path}/#{self.filename}") do |zipfile|
            # create the path for the file, if it doesn't exist
            fpath = File.join(self.path, zipfile.name)
            FileUtils.mkdir_p(File.dirname(fpath))
            zipfile.extract(fpath)
          end
          # sys = system("cd #{self.path};jar xf #{self.filename}")
          self.jar_last_modified = urlfile.last_modified
          self.jar_digest = Base64.b64encode(Digest::MD5.digest(urlfile.read)).strip
        end
      rescue SocketError, OpenURI::HTTPError, OpenSSL::SSL::SSLError => e
        if RAILS_ENV == 'production'
          additional_info = ''
        else
          additional_info = "\n#{e.message}\n\n#{e.backtrace.join("\n")}"
        end
        raise "There was a problem saving the curnit jar to the filesystem\n#{additional_info}"
      end
      begin
        curnit_xml_file = File.read("#{self.path}curnit.xml")
        if USE_LIBXML
          curnit_xml = XML::Parser.string(curnit_xml_file).parse.root
          self.uuid = curnit_xml.find("//void[@property='curnitId']/object[@class='net.sf.sail.core.uuid.CurnitUuid']/string").first.content
          self.root_pod_uuid =  curnit_xml.find("//void[@property='rootPodId']/object[@class='net.sf.sail.core.uuid.PodUuid']/string").first.content
          self.title = curnit_xml.find("//void[@property='title']/string").first.content
        else # use REXML
          curnit_xml = REXML::Document.new(curnit_xml_file)
          self.uuid = REXML::XPath.first(curnit_xml, "//void[@property='curnitId']/object[@class='net.sf.sail.core.uuid.CurnitUuid']/string").text
          self.root_pod_uuid =  REXML::XPath.first(curnit_xml, "//void[@property='rootPodId']/object[@class='net.sf.sail.core.uuid.PodUuid']/string").text
          self.title = REXML::XPath.first(curnit_xml, "//void[@property='title']/string").text
        end
      rescue => e
        raise "There was a problem reading attributes from the curnit.\n\n#{e.message}\n\n#{e.backtrace.join("\n")}"
      end
    end
  end

  def get_last_modified
    uri = URI.parse(self.url)
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        head = Net::HTTP.start(uri.host, uri.port) {|http| http.head(uri.path, 'User-Agent' => '')}
        if head.class == Net::HTTPOK
          self.jar_last_modified=Time::httpdate(head['Last-Modified'])
        else
          'jnlp not available'
        end
      end
    rescue SocketError
      "network unavailable"
    end
  end
end

