class Curnit < ActiveRecord::Base
  require 'net/http'
  set_table_name "sds_curnits"
  
  validates_presence_of :name, :url
  belongs_to :portal
  has_many :offerings, :order => "created_at DESC"
  has_many :pods
  before_save :check_jar
  
  require 'fileutils'
  require 'open-uri'
  require 'zip/zipfilesystem'

  # look for the pod in this curnit
  # returning a REXML object with the 
  # xmlencoded form of the pod if found
  # and nil if not found
  def find_podxml_in_jar(pod_id)
    if p = Pod.find(pod_id)
      Zip::ZipFile.open(self.jar_file_path, Zip::ZipFile::CREATE) do |jar|
        REXML::Document.new(jar.file.read("POD_#{p.uuid}.xml"))
      end
    end
  end

  def curnit_xml
    Zip::ZipFile.open(self.jar_file_path, Zip::ZipFile::CREATE) do |jar|
      curnit_xml = REXML::Document.new(jar.file.read("curnit.xml"))
    end
  end
    
  def check_always_update # if nil set to true
    self.always_update ||= true
  end
  
  def generate_filename
    self.filename = self.name.strip.downcase.gsub(/\W+/, '_').gsub(/^_+|_+$/, '')
  end

  # if no curnit jar exists then get curnit jar and set jar_digest and jar_last_modified
  # else if always_update then if external curnit last_modified newer than jar_last_modified then update_jar
  def check_jar
    if self.filename.blank?
      generate_filename
    end
    if self.jar_last_modified.blank? || self.always_update || self.local_jar_empty?
      self.update_jar
    end
  end

  def local_jar_empty?
    !self.jar_last_modified || !File.exists?(self.jar_file_path)
  end
  
  # deal with strange issue of chroot at railsapp/ in development
  # mode and railsapp/public/ in production on the server
  def jar_path
    prefix = if Dir.getwd =~ /\/public$/ then "" else "public/" end
    "#{prefix}curnits/#{self.id}/"
  end
  
  # >> c.jar_last_modified.iso8601.gsub(/\W/, '_')
  # => "2007_02_05T16_27_40_05_00"
  def jar_file_path
    "#{self.jar_path}#{self.filename}_#{self.jar_last_modified.iso8601.gsub(/\W/, '_')}.jar"
  end
  
  def update_jar
    if self.jar_last_modified.blank? || (self.jar_last_modified < self.get_last_modified)
      open(self.url) do |f|
        if  !File.exists?(self.jar_path)
          FileUtils.mkdir_p(self.jar_path)
        end
        self.jar_last_modified = f.last_modified
        File.open(jar_file_path, 'wb') {|j| j.write(f.read) }
        # x = system("cd #{jar_path}; jar xf #{jar_file_path}")
        self.jar_digest = Base64.b64encode(Digest::MD5.digest(f.read))
        Zip::ZipFile.open(self.jar_file_path, Zip::ZipFile::CREATE) do |jar|
          curnit_xml = REXML::Document.new(jar.file.read("curnit.xml"))
          self.uuid = REXML::XPath.first(curnit_xml, "//void[@property='curnitId']/object[@class='net.sf.sail.core.uuid.CurnitUuid']/string").text
          self.root_pod_uuid =  REXML::XPath.first(curnit_xml, "//void[@property='rootPodId']/object[@class='net.sf.sail.core.uuid.PodUuid']/string").text
          self.title = REXML::XPath.first(curnit_xml, "//void[@property='title']/string").text
        end
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
