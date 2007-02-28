class Bundle < ActiveRecord::Base
  set_table_name "sds_bundles"
  belongs_to :workgroup
  has_one :bundle_content
  has_many :socks
  
  attr_accessor :bc
  
  def self.find_by_workgroup(workgroup)
    Bundle.find(:all, :conditions => ["workgroup_id = :workgroup", {:workgroup => workgroup}])
  end
  
  def self.rebuild_pods_and_socks
    Pod.delete_all
    Sock.delete_all
    puts "Bundles to process: #{Bundle.count.to_s}\nprocessing: "
    Bundle.find(:all, :order => "created_at ASC").each do |b|
      b.process_content
      print '.'
    end
    Sock.export_to_file_system
    ""
  end

  def before_save
    self.bundle_content ||= BundleContent.new(:content => self.bc)
  end
  
  def after_create
    process_content
    self.process_status = 1
    self.save
  end
  
  # each sockPart references one pod and one associated rim_name
  def process_content
    session_bundle = REXML::Document.new(content).elements['sessionBundles']
    self.sail_curnit_uuid = session_bundle.attributes['curnitUUID']
    self.sail_session_uuid = session_bundle.attributes['sessionUUID']
    self.sail_session_start_time = SdsTime.java8601(session_bundle.attributes['start'])
    self.sail_session_end_time = SdsTime.java8601(session_bundle.attributes['stop'])
    session_bundle.elements.to_a('//sockParts').each do |sp_xml|
      uuid = sp_xml.attributes["podId"].to_s
      rim_name = sp_xml.attributes["rimName"].to_s
      shape = sp_xml.attributes["rimShape"].to_s
      rim_shape = case
        when shape == "[B" : "bytearray"
        when shape == "" : "text"
      end
      unless p = Pod.find_by_uuid_and_rim_name(uuid, rim_name)
        p = Pod.create(:curnit_id => self.workgroup.offering.curnit.id, :uuid => uuid, :rim_name => rim_name, :rim_shape => rim_shape)
      end
      # now for each sockPart process all the sockEntries creating socks
      REXML::Document.new(sp_xml.to_s).elements.to_a('//sockEntries').each do |se_xml|
        value = se_xml.attributes["value"].to_s
        ms_offset = se_xml.attributes["millisecondsOffset"].to_i
        s = Sock.create(:bundle_id => self.id, :pod_id => p.id, :value => value, :ms_offset => ms_offset, 
          :duplicate => (if p.socks.empty? then false else p.socks.last.value == value end))
      end      
    end
  end
    
end
