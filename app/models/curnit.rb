class Curnit < ActiveRecord::Base
  require 'net/http'
  set_table_name "sds_curnits"

  attr_reader :podxml_cache, :test
  
  validates_presence_of :name, :url
  belongs_to :portal
  has_many :offerings, :order => "created_at DESC"
  has_many :pods
  
  before_save { |c| c.url.strip! }
  before_save :check_for_jar
  
  require 'fileutils'
  require 'open-uri'
  require 'zip/zipfilesystem'
    
  def after_initialize
    @podxml_cache = Hash.new
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
    
  def check_always_update # if nil set to true
    self.always_update ||= true
  end

  # if no curnit jar exists then get curnit jar and set jar_digest and jar_last_modified
  # else if always_update then if external curnit last_modified newer than jar_last_modified then update_jar
  def check_for_jar
    if self.jar_last_modified.blank? || self.always_update || self.local_jar_empty?
      self.update_jar
    end
  end

  def local_jar_empty?
    !self.jar_last_modified || !File.exists?(self.jar_path)
  end
  
  def filename
    File.basename(self.url)
  end
  
  # deal with strange issue of chroot at railsapp/ in development
  # mode and railsapp/public/ in production on the server
  def path  
    "#{SdsCache.instance.path}#{self.portal.id}/curnits/#{self.id}/"
  end
  
  def jar_path
    "#{self.path}#{self.filename}"
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
    if self.jar_last_modified.blank? || (self.jar_last_modified < self.get_last_modified)
      url_string = self.url
      open(url_string) do |urlfile|
        if File.exists?(self.path)
          FileUtils.rmtree(Dir.glob(self.path + '*'))
        else
          FileUtils.mkdir_p(self.path)
        end
        File.open(self.jar_path, 'wb') {|jar| jar.write(urlfile.read) }
        sys = system("cd #{self.path};jar xf #{self.filename}")
        self.jar_last_modified = urlfile.last_modified
        self.jar_digest = Base64.b64encode(Digest::MD5.digest(urlfile.read)).strip
      end
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

# Curnit.find_all.each {|c| c.jar_last_modified=nil; print "#{c.id}: #{c.name}"; begin c.save! rescue print " error " ensure puts end }
# Feb 13, 2007
#
# 7: Airbag complete (testing REST creation)
# 8: airbag test curnit error 
# 9: basic curnit (zip) error 
# 10: full airbag curnit1B2M2Y8AsgTpgAmY7PhCfg==
# 11: velocity and kinematics curnit error 
# 12: malaria (converted-4439, zip) error 
# 13: global warming: virtual earth curnit         error 
# 14: Airbag3 error 
# 15: Airbag3 error 
# 16: Hiroki Airbag! Sept. 14 error 
# 17: Hiroki Airbag Sept. 14 error 
# 18: Hiroki Airbag Sept. 14 error 
# 19: Hiroki Airbag Sept. 14 error 
# 20: Hiroki Oct 4 copy airbag error 
# 21: [Sail] Airbags Complete1B2M2Y8AsgTpgAmY7PhCfg==
# 22: [Sail] Airbags Complete1B2M2Y8AsgTpgAmY7PhCfg==
# 23: [SAIL] Airbags complete1B2M2Y8AsgTpgAmY7PhCfg==
# 24: Full Airbag Snapshot1B2M2Y8AsgTpgAmY7PhCfg==
# 25: Test Airbag Model Step in Old Wise Project (23305)1B2M2Y8AsgTpgAmY7PhCfg==
# 26: Airbag Complete (19530) version 161B2M2Y8AsgTpgAmY7PhCfg==
# 27: Concord Curnit1B2M2Y8AsgTpgAmY7PhCfg==
# 28: Chemical Reactions Test1B2M2Y8AsgTpgAmY7PhCfg==
# 29: Airbag3 error 
# 30: Chemical Reactions1B2M2Y8AsgTpgAmY7PhCfg==
# 31: Chemical Reactions Version A1B2M2Y8AsgTpgAmY7PhCfg==
# 32: Chemical Reactions Version B1B2M2Y8AsgTpgAmY7PhCfg==
# 33: full airbag snapshot version 201B2M2Y8AsgTpgAmY7PhCfg==
# 34: Chemical Reactions Sail Conversion master copy1B2M2Y8AsgTpgAmY7PhCfg==
# 35: Chemical Reactions Sail Conversion master copy1B2M2Y8AsgTpgAmY7PhCfg==
# 36: Chemical Reactions (A)1B2M2Y8AsgTpgAmY7PhCfg==
# 37: Chemical Reactions (B)1B2M2Y8AsgTpgAmY7PhCfg==
# 38: Chemical Reactions Sail Conversion alternate copy1B2M2Y8AsgTpgAmY7PhCfg==
# 39: Global Warming test curnit1B2M2Y8AsgTpgAmY7PhCfg==
# 40: Global Warming Test Curnit1B2M2Y8AsgTpgAmY7PhCfg==
# 41: ChallengeQuest Global Warming1B2M2Y8AsgTpgAmY7PhCfg==
# 42: ChallengeQuestThursday1B2M2Y8AsgTpgAmY7PhCfg==
# 43: OTrunk Test1B2M2Y8AsgTpgAmY7PhCfg==
# 44: (SAIL) Global Warming: Virtual Earth version 41B2M2Y8AsgTpgAmY7PhCfg==
# 45: TrudiTestingTheConverter1B2M2Y8AsgTpgAmY7PhCfg==
# 46: Ken SAILism Convert1B2M2Y8AsgTpgAmY7PhCfg==
# 47: Trudi's Chem Reactions Test1B2M2Y8AsgTpgAmY7PhCfg==
# 48: Chemical Reactions Test by Trudi1B2M2Y8AsgTpgAmY7PhCfg==
# 49: Trudi's Test of Chem Reactions-Netlogo1B2M2Y8AsgTpgAmY7PhCfg==
# 50: Trudi's Global with Eds new files1B2M2Y8AsgTpgAmY7PhCfg==
# 51: Chemical Reactions Test by Trudi V21B2M2Y8AsgTpgAmY7PhCfg==
# 52: Global Warming Ariel Release1B2M2Y8AsgTpgAmY7PhCfg==
# 53: (SAIL) Global Warming version 6 (no slider logging)1B2M2Y8AsgTpgAmY7PhCfg==
# 54: Chemical Reactions (B-final)1B2M2Y8AsgTpgAmY7PhCfg==
# 55: airbags fullsnap shot 221B2M2Y8AsgTpgAmY7PhCfg==
# 56: [SAIL] TELS Chemistry: Chemical Reactions (1)1B2M2Y8AsgTpgAmY7PhCfg==
# 57: [SAIL] TELS Chemistry: Chemical Reactions (2)1B2M2Y8AsgTpgAmY7PhCfg==
# 58: [SAIL] TELS Chemistry: Chemical Reactions (3)1B2M2Y8AsgTpgAmY7PhCfg==
# 59: [SAIL] TELS Chemistry: Chemical Reactions (4)1B2M2Y8AsgTpgAmY7PhCfg==
# 60: OTrunk Untangled Test
# 61: otrunk-curnit-untangled1B2M2Y8AsgTpgAmY7PhCfg==
# 62: otrunk-curnit-external-diytest1B2M2Y8AsgTpgAmY7PhCfg==
# 63: otrunk-curnit-external-diytest1B2M2Y8AsgTpgAmY7PhCfg==
# 64: otrunk-curnit-external-diytest-6-11B2M2Y8AsgTpgAmY7PhCfg==
# 65: otrunk-curnit-external-diytest-6-41B2M2Y8AsgTpgAmY7PhCfg==
# 66: Full Curtain Airbags1B2M2Y8AsgTpgAmY7PhCfg==
# 67: Apollo, Stop that Global Warming!1B2M2Y8AsgTpgAmY7PhCfg==
# 68: Better Living Through Chemicals (V1)1B2M2Y8AsgTpgAmY7PhCfg==
# 69: Better Living Through Chemicals (V2)1B2M2Y8AsgTpgAmY7PhCfg==
# 70: Better Living Through Chemicals (V3)1B2M2Y8AsgTpgAmY7PhCfg==
# 71: Better Living Through Chemicals (V4)1B2M2Y8AsgTpgAmY7PhCfg==
# 72: Two kinds of processes1B2M2Y8AsgTpgAmY7PhCfg==
