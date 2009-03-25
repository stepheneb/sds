# == Schema Information
# Schema version: 58
#
# Table name: sds_bundles
#
#  id                      :integer(11)   not null, primary key
#  workgroup_id            :integer(11)   
#  workgroup_version       :integer(11)   
#  content                 :text          
#  created_at              :datetime      
#  process_status          :integer(11)   
#  sail_session_start_time :datetime      
#  sail_session_end_time   :datetime      
#  sail_curnit_uuid        :string(255)   
#  sail_session_uuid       :string(255)   
#  content_well_formed_xml :boolean(1)    
#  bundle_content_id       :integer(11)   
#  processing_error        :text          
#

class Bundle < ActiveRecord::Base
	require 'zlib'
	require 'b64'
	
  include ActionController::UrlWriter

#  acts_as_reportable
  belongs_to :workgroup
  belongs_to :bundle_content
  belongs_to :original_bundle_content, :class_name => "BundleContent"
  
  has_one :log_bundle
  
  has_many :blobs

  has_many :socks do
    def find_notes
      find(:all).select {|s| s.pod.pas_type == 'note'}
    end
    def find_model_activity_datasets
      find(:all).select {|s| s.pod.pas_type == 'model_activity_data' || (s.pod.pas_type == "ot_learner_data" && s.text =~ /OTModelActivityData/)}
    end
    def find_curnit_maps
      find(:all, :order => "ms_offset DESC").select {|s| s.pod.pas_type == 'curnit_map'}
    end
    def by_time_asc
      find(:all, :order => "ms_offset ASC")
    end
  end

#  cattr_accessor :console_log
  cattr_reader :process_errors, :session_bundle

  if USE_LIBXML 
    @@xml_parser = XML::Parser.new
  end
  
  attr_accessor :bc
  
  def valid
  end
 
  before_create :create_bundle_contents
  after_create :mark_bundle_processed
#  after_create  :process_bundle_contents
 
  def create_bundle_contents
    unless self.bc.empty?
      self.bundle_content = BundleContent.new(:content => self.bc)
    end
  end
  
  def process_bundle_contents
    self.save_to_file_system
    self.process_content
    self.process_status = 1
    self.has_data = self.socks.count > 0
    self.save!
  end

  def mark_bundle_processed
    self.sail_session_modified_time = Time.now.gmtime
    self.process_status = 3
    self.save!
  end
  
  def self.find_by_workgroup(workgroup)
    Bundle.find(:all, :conditions => ["workgroup_id = :workgroup", {:workgroup => workgroup}])
  end
  
  def self.find_nth(nth)
    Bundle.find(:all)[nth-1]
  end

  def self.rebuild_pods_and_socks(start_over=true)
    tracker = TimeTracker.new
    tracker.start
    if start_over
      print "Setting Bundle process status to 0 for all #{Bundle.count.to_s} Bundles ... "
      result = Bundle.update_all("process_status = 0")
      result = Bundle.update_all("processing_error = ''")
      tracker.mark; puts
      print "Erasing resources cached in filesystem generated from processing Bundles (includes Workgroups, Socks) ... "
      Portal.find(:all).each do |p|
        path = "#{SdsCache.instance.path}#{p.id}/offerings"
        if File.exists?(path)
          FileUtils.rmtree(Dir.glob("#{path}*"))
        end
      end
      tracker.mark; puts
      puts "Erasing Pods from cache ... "
      Pod.find(:all).each do |p|
        if p.curnit
          path = p.path
          if File.exists?(path)
            FileUtils.rmtree(Dir.glob("#{path}*"))
          end
        end
      end
      tracker.mark; puts
      print "Deleting: #{Pod.count.to_s} Pods from the database ... "
      Pod.delete_all
      tracker.mark; puts
      Sock.delete_all
      tracker.mark; puts
    end
    Bundle.process_bundles
    tracker.stop
  end
    
  def self.process_bundles
    bundle_count = Bundle.count
    puts "Processing Bundles in database, recreating Pods and Socks in database and cache ..."
    puts "Bundles to process: #{bundle_count}:"
    tracker = TimeTracker.new
    tracker.start
    @@process_errors = []
    count = 1
    print "#{sprintf("%5d", count)}: "
    Bundle.find(:all, :order => "created_at ASC").each do |b|
      if b.process_status != 1
        begin
          b.save_to_file_system
          b.process_content
          b.update_attribute(:process_status, 1) 
          print 'p'
        rescue => e
          b.update_attributes(:process_status => 2, :processing_error => e) 
          print 'x'
        end
      else
        print '.'
      end
      if count.remainder(50) == 0
        print '  '
        tracker.mark
        ave = tracker.elapsed / count
        projected = (bundle_count - count) * ave
        print " :: ave: #{TimeTracker.seconds_to_s(ave)}, projected: #{TimeTracker.seconds_to_s(projected)}"
        print "\n#{sprintf("%5d", count)}: "
      end
      count += 1
    end
    tracker.stop
  end
  
  def process_content(console_log=nil)
    if parse_content_xml     
      content_well_formed_xml = true
      process_sail_session_attributes
      begin
        process_ot_blob_resources
      rescue => e
        logger.warn "Couldn't extract blob resources! (#{e})"
      end
      process_sock_parts(console_log)
      if self.sail_session_modified_time == nil
        self.sail_session_modified_time = calc_modified_time.gmtime
      end
    else
      content_well_formed_xml = false
    end
  end

  # need to know the kind of exceptions LIBXML might throw with bad XML also
  def parse_content_xml
    if USE_LIBXML
      @@xml_parser.string = self.bundle_content.content
      nil || @@session_bundle = @@xml_parser.parse.root
    else
      begin
        nil || @@session_bundle = REXML::Document.new(self.bundle_content.content).root
      rescue REXML::ParseException
        nil
      end        
    end
  end
  
  def process_sail_session_attributes
    if USE_LIBXML
      self.sail_curnit_uuid = @@session_bundle.sds_get_attribute_with_default('curnitUUID', 'x' * 36)
      self.sail_session_uuid = @@session_bundle.sds_get_attribute_with_default('sessionUUID', 0)
      self.sail_session_start_time = @@session_bundle.sds_get_attribute_with_default('start', nil) { |t| SdsTime.fix_java8601(t).getutc }
      self.sail_session_end_time = @@session_bundle.sds_get_attribute_with_default('stop', nil) { |t| SdsTime.fix_java8601(t).getutc }
      self.sail_session_modified_time = @@session_bundle.sds_get_attribute_with_default('modified', nil) { |t| SdsTime.fix_java8601(t).getutc }
    else
      self.sail_curnit_uuid = @@session_bundle.attributes['curnitUUID'] || 'x' * 36
      self.sail_session_uuid = @@session_bundle.attributes['sessionUUID'] || 0
      self.sail_session_start_time = SdsTime.fix_java8601(@@session_bundle.attributes['start']) || nil
      self.sail_session_end_time = SdsTime.fix_java8601(@@session_bundle.attributes['stop']) || nil
      self.sail_session_modified_time = SdsTime.fix_java8601(@@session_bundle.attributes['modified']) || nil
    end
  end
  
  def calc_modified_time
    # take the sail_session_start_time and increment by the msOffset time of the newest sockentry in the bundle
    starttime = self.sail_session_start_time
    if ! starttime
      return (self.sail_session_end_time ? self.sail_session_end_time : self.created_at)
    else
      if self.socks.count > 0
        modtime = starttime + (self.socks.sort{|a,b| b.ms_offset <=> a.ms_offset}.compact[0].ms_offset/1000)
        return modtime.getgm
      else
        return (self.sail_session_end_time ? self.sail_session_end_time : self.created_at)
      end
    end
  end
  
  # each sockPart references one pod and one associated rim_name
  def process_sock_parts(console_log=nil)
    curnit = self.workgroup.offering.curnit
    if USE_LIBXML
      @@session_bundle.find('//sockParts').each do |sockPart|
        uuid = sockPart.find('@podId').first.value
        rim_name = sockPart.find('@rimName').first.value
        shape = sockPart.find('@rimShape').first
        rim_shape = Pod.pod_shape_map[shape ? shape.value : '']
        unless p = Pod.find_by_uuid_and_rim_name_and_curnit_id(uuid, rim_name, curnit.id)
          if console_log
            puts
            puts '------' * 12
            puts "Pod.create!(:curnit_id => #{self.workgroup.offering.curnit.id}, :uuid => #{uuid}, :rim_name => #{rim_name}, :rim_shape => #{rim_shape})"
            puts '------' * 12
            puts
          end
          p = Pod.create!(:curnit_id => curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
          # p = Pod.new(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
        end
        sockPart.find('sockEntries').each do |sockEntry|
          value = sockEntry.find('@value').first.value
          ms_offset = sockEntry.find('@millisecondsOffset').first.value
          if console_log
            puts
            puts "Sock.create!(:bundle_id => #{self.id}, \n:value => #{value.length},\n:ms_offset => #{ms_offset}, :pod_id => #{p.id})"
          end
          Sock.create!(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id)
          # Sock.new(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
        end
      end
    else # use REXML
      @@session_bundle.elements.to_a('//sockParts').each do |sockPart|
        uuid = sockPart.attributes["podId"].to_s
        rim_name = sockPart.attributes["rimName"].to_s
        shape = sockPart.attributes["rimShape"].to_s
        rim_shape = Pod.pod_shape_map[shape ? shape : '']
        unless p = Pod.find_by_uuid_and_rim_name_and_curnit_id(uuid, rim_name, curnit.id)
          if console_log
            puts
            puts '------' * 12
            puts "Pod.create!(:curnit_id => #{self.workgroup.offering.curnit_id}, :uuid => #{uuid}, :rim_name => #{rim_name}, :rim_shape => #{rim_shape})"
            puts '------' * 12
            puts
          end
          p = Pod.create!(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
          # p = Pod.new(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
        end
        sockPart.elements.to_a('./sockEntries').each do |sockEntry|
          value = sockEntry.attributes["value"].to_s
          ms_offset = sockEntry.attributes["millisecondsOffset"].to_i
          if console_log
            puts
            puts "Sock.create!(:bundle_id => #{self.id}, \n:value => #{value.length},\n:ms_offset => #{ms_offset}, :pod_id => #{p.id})"
          end
          Sock.create!(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id)
          # Sock.new(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => 3, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
        end
      end
    end
  end
  
  def copy_bundle(destination_workgroup)
    # we need to modify the otrunk uuid and OTUser uuid and name in any ot_learner_data before we copy the bundle
    pid = spawn do
      # get the bundle contents
      content_xml = REXML::Document.new(self.bundle_content.content).root
      # for each ot_learner_data sock entry
      content_xml.elements.each("//sockParts[@rimName='ot.learner.data']/sockEntries") { |sock|
        begin
          #   unpack it
          ot_learner_data_xml = REXML::Document.new(b64gzip_unpack(sock.attributes["value"])).root
          #   modify it
          otrunk_id = UUID.timestamp_create().to_s
          user_id = UUID.timestamp_create().to_s
          ot_learner_data_xml.attributes["id"] = otrunk_id
          ot_learner_data_xml.elements["//otrunk/objects/OTStateRoot/userMap/entry"].attributes["key"] = user_id
          user_object = ot_learner_data_xml.elements["/otrunk/objects/OTStateRoot/userMap/entry/OTReferenceMap/user/OTUserObject"]
          user_object.attributes["id"] = user_id
          user_object.attributes["name"] = destination_workgroup.name
          #   repack it and save it to the bundle contents
          sock.attributes["value"] = b64gzip_pack(ot_learner_data_xml.to_s)
        rescue
          logger.warn "Couldn't modify sock entry in bundle #{self.id}"
        end
      }
         
      new_bundle = Bundle.create!(:workgroup_id => destination_workgroup.id, :workgroup_version => destination_workgroup.version, :bc => content_xml.to_s)
    end
    wait(pid)
    # FIXME need to figure out if we were successfull and either return true or thrown an exception
  end
  
  def process_ot_blob_resources(reparse = false)
    num = 0
    bc = self.bundle_content
		raise "No bundle contents!" if ! bc
    if (reparse || (! @@session_bundle)) 
      parse_content_xml
    end

    if USE_LIBXML
			sdsr = @@session_bundle.find("//sdsReturnAddresses").first
			raise "Invalid return address!" if ! sdsr
      host = URI.parse(sdsr.content).host
      @@session_bundle.find("//sockParts[@rimName='ot.learner.data']/sockEntries").each do |sock|
        @@xml_parser.string = b64gzip_unpack(sock.attributes["value"])
        ot_learner_data_xml = @@xml_parser.parse.root
        ot_learner_data_xml.find("//OTBlob/src").each do |raw|
          next if (raw.content =~ /blobs\/[0-9]+\/raw\/[0-9a-zA-Z]+$/)
          num += 1
          blob = Blob.find_or_create_by_content(:content => raw.content, :bundle => self)
          raw.content = raw_blob_url(:id => blob, :token => blob.token, :host => host )
        end
        sock.find("@value").first = b64gzip_pack(ot_learner_data_xml.to_s)
      end
    else
      sdsr = @@session_bundle.elements["//sdsReturnAddresses"]
      raise "Invalid return address!" if ! sdsr
      host = URI.parse(sdsr.text).host
      @@session_bundle.elements.each("//sockParts[@rimName='ot.learner.data']/sockEntries") do |sock|
        #   unpack it
        ot_learner_data_xml = REXML::Document.new(b64gzip_unpack(sock.attributes["value"])).root
        #   modify it
        ot_learner_data_xml.elements.each("//OTBlob/src") do |raw|
          next if (raw.text =~ /blobs\/[0-9]+\/raw\/[0-9a-zA-Z]+$/)
          num += 1
          blob = Blob.find_or_create_by_content(:content => raw.text, :bundle => self)
          raw.text = raw_blob_url(:id => blob, :token => blob.token, :host => host )
        end
        #   repack it and save it to the bundle contents
        sock.attributes["value"] = b64gzip_pack(ot_learner_data_xml.to_s)
      end
    end
    if num > 0
      # save the original bundle_content so we can always get the unmodified content
      self.original_bundle_content = BundleContent.new(:content => bc.content)
      self.save
      bc.content = @@session_bundle.to_s
      bc.save
    end
    return num
  end
    
  # class method returns filesystem path to
  # bundle directory root
  def path
    "#{SdsCache.instance.path}#{self.workgroup.offering.portal.id}/offerings/#{self.workgroup.offering.id}/workgroups/#{self.workgroup.id}/bundles/#{self.id}/"
  end
  
  def filename
    "bundle_#{self.id.to_s}_bundle_content"
  end

  def save_to_file_system
    begin
      FileUtils.mkdir_p(self.path) unless File.exists?(self.path)
      File.open("#{self.path}#{self.filename}", "w") { |f| f.write self.bundle_content.content }
    end
  end    

  def sail_session_start_time
    begin
      read_attribute("sail_session_start_time").getlocal
    rescue
      nil
    end
  end
  
  def sail_session_end_time
    begin
      read_attribute("sail_session_end_time").getlocal
    rescue
      nil
    end
  end
  
  # return a hash of uuids and their associated attributes
  # {uuid => {pod => p, title => "title", activity => #num, step => #num}}
  def curnitmap
    cmaps = self.socks.find_curnit_maps
    map_sock = ((cmaps.length > 0) ? cmaps[0] : nil)
    
    if map_sock == nil
      return nil
    end
    data = {}
    
    # load the xml
    xml = REXML::Document.new(map_sock.value).root
    # debugger
    # for each <project>
    xml.children.each do |pr_xml|
      # save proj data
      # logger.info("-------proj-------------\n#{pr_xml}\n----------------------")
      p_uuid =  pr_xml.attributes['podUUID'].to_s
      p_title = pr_xml.attributes['title'].to_s
      # logger.info("Saving project: #{p_uuid} -- #{p_title}")
      # logger.info("project")
      data[p_uuid] = {"title" => p_title}
      # for each <activity>
      # pr_xml.elements.each("//activity") {|ac_xml|
      pr_xml.children.each do |ac_xml|
        # save act data
        # logger.info("-------act-------------\n#{ac_xml}\n----------------------")
        a_uuid = ac_xml.attributes['podUUID'].to_s
        act_num = ac_xml.attributes['number'].to_i + 1 ## Increment by one, because the curnitmap counts from 0
        a_title = ac_xml.attributes['title'].to_s
        # logger.info("Saving act: #{a_uuid} -- #{act_num} -- #{a_title}")
        # logger.info("activity")
        data[a_uuid] = {"title" => a_title, "activity_number" => act_num, "step_number" => nil }        
        # for each <step>
        # logger.info(ac_xml)
        # ac_xml.elements.each("//step") {|st_xml|
        ac_xml.children.each do |st_xml|
          # save step data
          # logger.info("------step-------------\n#{st_xml}\n----------------------")
          s_uuid = st_xml.attributes['podUUID'].to_s
          step_num = st_xml.attributes['number'].to_i + 1 ## curnitmap starts at 0, so increment
          s_title = st_xml.attributes['title'].to_s
          type = st_xml.attributes['type'].to_s
          # logger.info("step")
          # logger.info("Saving step: #{s_uuid} -- #{act_num} -- #{step_num} -- #{type} -- #{s_title}")
          data[s_uuid] = {"activity_number" => act_num, "step_number" => step_num, "title" => s_title, "type" => type}
        end
      end
    end
    data
  end
  
  def sds_return_address
    bxml =  REXML::Document.new(self.bundle_content.content).root
    uri = URI.parse(bxml.elements["//sdsReturnAddresses"].text)
    return uri
  end
  
  private
  
  def b64gzip_unpack(str)
    Zlib::GzipReader.new(StringIO.new(B64::B64.decode(str))).read
  end
  
  def b64gzip_pack(str)
    gzip_string_io = StringIO.new()
    gzip = Zlib::GzipWriter.new(gzip_string_io)
    gzip.write(str)
    gzip.close
    gzip_string_io.rewind
    B64::B64.encode(gzip_string_io.string)
  end
end
