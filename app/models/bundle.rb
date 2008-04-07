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
  set_table_name "sds_bundles"

#  acts_as_reportable
  belongs_to :workgroup
  belongs_to :bundle_content
  
  has_one :log_bundle

  has_many :socks do
    def find_notes
      find(:all).select {|s| s.pod.pas_type == 'note'}
    end
    def find_model_activity_datasets
      find(:all).select {|s| s.pod.pas_type == 'model_activity_data'}
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
  
  def before_create
    unless self.bc.empty?
      self.bundle_content = BundleContent.new(:content => self.bc)
    end
  end
  
  def after_create
    self.save_to_file_system
    self.process_content
    self.process_status = 1
    self.has_data = self.socks.count > 0
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
    bundle.count = Bundle.count
    puts "Processing Bundles in database, recreating Pods and Socks in database and cache ..."
    puts "Bundles to process: #{bundle.count}:"
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
        projected = (bundle.count - count) * ave
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
      process_sock_parts(console_log)
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
      self.sail_session_start_time = @@session_bundle.sds_get_attribute_with_default('start', self.created_at) { |t| SdsTime.fix_java8601(t).getutc }
      self.sail_session_end_time = @@session_bundle.sds_get_attribute_with_default('stop', self.created_at) { |t| SdsTime.fix_java8601(t).getutc }
    else
      self.sail_curnit_uuid = @@session_bundle.attributes['curnitUUID'] || 'x' * 36
      self.sail_session_uuid = @@session_bundle.attributes['sessionUUID'] || 0
      self.sail_session_start_time = SdsTime.fix_java8601(@@session_bundle.attributes['start']) || self.created_at
      self.sail_session_end_time = SdsTime.fix_java8601(@@session_bundle.attributes['stop']) || self.created_at
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
          p = Pod.create!(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
          # p = Pod.new(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
        end
        sockPart.find('sockEntries').each do |sockEntry|
          value = sockEntry.find('@value').first.value
          ms_offset = sockEntry.find('@millisecondsOffset').first.value
          if console_log
            puts
            puts "Sock.create!(:bundle_id => #{self.id}, \n:value => #{value.length},\n:ms_offset => #{ms_offset}, :pod_id => #{p.id}, :duplicate => #{(if p.socks.empty? then false else p.socks.last.value == value end)})"
          end
          Sock.create!(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
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
            puts "Pod.create!(:curnit_id => #{self.workgroup.offering.curnit.id}, :uuid => #{uuid}, :rim_name => #{rim_name}, :rim_shape => #{rim_shape})"
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
            puts "Sock.create!(:bundle_id => #{self.id}, \n:value => #{value.length},\n:ms_offset => #{ms_offset}, :pod_id => #{p.id}, :duplicate => #{(if p.socks.empty? then false else p.socks.last.value == value end)})"
          end
          Sock.create!(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
          # Sock.new(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => 3, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
        end
      end
    end
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

end
