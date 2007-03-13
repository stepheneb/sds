class Bundle < ActiveRecord::Base
  set_table_name "sds_bundles"
  belongs_to :workgroup
  belongs_to :bundle_content
  has_many :socks

#  cattr_accessor :console_log
  cattr_reader :process_errors, :session_bundle

  if USE_LIBXML 
    @@xml_parser = XML::Parser.new
  end
  
  attr_accessor :bc
  
  def before_save
    self.bundle_content ||= BundleContent.new(:content => self.bc)
  end
  
  def after_create
    self.save_to_file_system
    self.process_content
    self.process_status = 1
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
      tracker.mark
      print "Erasing resources cached in filesystem generated from processing Bundles (includes Workgroups, Socks) ... "
      Portal.find(:all).each do |p|
        path = "#{SdsCache.instance.path}#{p.id}/offerings"
        if File.exists?(path)
          FileUtils.rmtree(Dir.glob("#{path}*"))
        end
      end
      tracker.mark
      print "Erasing Pods from sds_cache ... "
      Pod.find(:all).each do |p| 
        path = p.path
        if File.exists?(path)
          FileUtils.rm Dir.glob("#{path}*")
        end
      end
      tracker.mark
      print "Deleting: #{Pod.count.to_s} Pods from the database ... "
      Pod.delete_all
      tracker.mark
      Sock.delete_all
      tracker.mark
    end
    Bundle.process_bundles
    tracker.stop
  end
    
  def self.process_bundles
    bundle_count = Bundle.count
    puts "Processing Bundles in database, recreating Pods and Socks in database and sds_cache ..."
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
        print " :: ave: #{tracker.seconds_to_s(ave)}, projected: #{tracker.seconds_to_s(projected)}"
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
  
  def parse_content_xml
    if USE_LIBXML
      @@xml_parser.string = self.bundle_content.content
      nil || @@session_bundle = @@xml_parser.parse.root
    else
      nil || @@session_bundle = REXML::Document.new(self.content).root
    end
  end
  
  def process_sail_session_attributes
    if USE_LIBXML
      self.sail_curnit_uuid = @@session_bundle.sds_get_attribute_with_default('curnitUUID', curnit.uuid)
      self.sail_session_uuid = @@session_bundle.sds_get_attribute_with_default('sessionUUID', 0)
      self.sail_session_start_time = @@session_bundle.sds_get_attribute_with_default('start', self.created_at) { |t| SdsTime.java8601(t) }
      self.sail_session_end_time = @@session_bundle.sds_get_attribute_with_default('stop', self.created_at) { |t| SdsTime.java8601(t) }
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
            puts ":curnit_id => #{self.workgroup.offering.curnit.id}, :uuid => #{uuid}, :rim_name => #{rim_name}, :rim_shape => #{rim_shape}"
          end
          # p = Pod.create!(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
          p = Pod.new(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
        end
        sockPart.find('sockEntries').each do |sockEntry|
          value = sockEntry.find('@value').first.value
          ms_offset = sockEntry.find('@millisecondsOffset').first.value
          if console_log
            puts ":bundle_id => #{self.id}, :value => #{value}, :ms_offset => #{ms_offset}, :pod_id => #{p.id}, :duplicate => #{(if p.socks.empty? then false else p.socks.last.value == value end)}"
          end
          # Sock.create!(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => p.id, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
          Sock.new(:bundle_id => self.id, :value => value, :ms_offset => ms_offset, :pod_id => 3, :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
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
end
