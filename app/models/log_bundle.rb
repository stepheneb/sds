class LogBundle < ActiveRecord::Base
  set_table_name "sds_log_bundles"
  
  belongs_to :workgroup
  belongs_to :bundle
  
  before_save :process_content
  
  def process_content
    # extract session uuid
    # extract curnit uuid
    if parse_content_xml     
      # content_well_formed_xml = true
      process_session_attributes
      self.bundle = Bundle.find(:first, :conditions => ["sail_curnit_uuid = ? && sail_session_uuid = ?", self.sail_curnit_uuid, self.sail_session_uuid])
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
      self.sail_curnit_uuid = @@logs_bundle.sds_get_attribute_with_default('curnitUUID', 'x' * 36)
      self.sail_session_uuid = @@logs_bundle.sds_get_attribute_with_default('sessionUUID', 0)
    else
      self.sail_curnit_uuid = @@logs_bundle.attributes['curnitUUID'] || 'x' * 36
      self.sail_session_uuid = @@logs_bundle.attributes['sessionUUID'] || 0
    end
  end
end
