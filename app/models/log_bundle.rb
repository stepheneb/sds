class LogBundle < ActiveRecord::Base
  set_table_name "sds_log_bundles"
  require 'cgi'
  
  belongs_to :workgroup
  belongs_to :bundle
  
  before_create :process_content
  before_save :associate_bundle
  
  if USE_LIBXML 
    @@xml_parser = XML::Parser.new
  end
  
  def extracted_content
    # basically pull each sockEntry value, associate with the timestamp and return a hash: hash[ms] = [value, value, ...]
    lines = self.content.scan(/<sockEntries value="([^"]+)"\/>/)
    self.content.scan(/<sockEntries value="([^"]+)" millisecondsOffset="(\d+)"\/>/).each do |m|
      lines << m
    end
    out = {}
    lines.each do |l|
      l[0]
      if (l[1])
        out[l[1].to_i] ||= []
        out[l[1].to_i] << l[0].gsub("&#9;", "&nbsp;&nbsp;&nbsp;&nbsp;")
      else
        out[0] ||= []
        out[0] << l[0].gsub("&#9;", "&nbsp;&nbsp;&nbsp;&nbsp;")
      end
    end
    return out
  end
  
  def associate_bundle
    if self.sail_session_uuid.length == 36
      self.bundle = Bundle.find(:first, :conditions => ["sail_session_uuid = ?", self.sail_session_uuid])
    end
  end
  
  def bundle
    if bid = read_attribute(:bundle_id)
      Bundle.find(bid)
    else
      self.save
      if bid = read_attribute(:bundle_id)
        Bundle.find(bid)
      else
        nil
      end
    end
  end
  
  def process_content
    # extract session uuid
    # extract curnit uuid
    if parse_content_xml     
      # content_well_formed_xml = true
      process_session_attributes
    else
      # content_well_formed_xml = false
    end
  end

  def parse_content_xml
    if USE_LIBXML
      @@xml_parser.string = self.content
      nil || @@logs_bundle = @@xml_parser.parse.root
    else
      begin
        nil || @@logs_bundle = REXML::Document.new(self.content).root
      rescue REXML::ParseException
        nil
      end        
    end
  end
  
  def process_session_attributes
    if USE_LIBXML
      self.sail_curnit_uuid = @@logs_bundle.sds_get_attribute_with_default('curnitUUID', 0)
      self.sail_session_uuid = @@logs_bundle.sds_get_attribute_with_default('sessionUUID', 0)
    else
      self.sail_curnit_uuid = @@logs_bundle.attributes['curnitUUID'] || 0
      self.sail_session_uuid = @@logs_bundle.attributes['sessionUUID'] || 0
    end
  end
end
