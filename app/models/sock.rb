# == Schema Information
# Schema version: 58
#
# Table name: sds_socks
#
#  id         :integer(11)   not null, primary key
#  created_at :datetime      
#  ms_offset  :integer(11)   
#  value      :text          
#  bundle_id  :integer(11)   
#  pod_id     :integer(11)   
#  duplicate  :boolean(1)    
#
require 'zlib'
require 'b64'

class Sock < ActiveRecord::Base
  
#  acts_as_reportable
  belongs_to :bundle
  belongs_to :pod
#  has_one :model_activity_dataset
  has_many :model_activity_datasets
  
  if USE_LIBXML 
    @@xml_parser = XML::Parser.new
  end

  def after_save
    self.save_to_file_system
    if self.pod.pas_type == "model_activity_data" || self.pod.pas_type == "ot_learner_data"
      if self.model_activity_datasets.count > 0
        self.model_activity_datasets.each {|mad| mad.save }
      elsif self.has_model_activity_data?
        xml = nil
        if (self.pod.pas_type == "ot_learner_data")
          xml = REXML::Document.new(self.unpack_gzip_b64_value)
        else
          xml = REXML::Document.new(self.value)
        end
        element_name = self.pod.pas_type == "model_activity_data" ? "modelactivitydata" : "OTModelActivityData"
        xml.elements.each("//#{element_name}") do |mad_xml|
          self.model_activity_datasets << ModelActivityDataset.create!(:content => mad_xml.to_s, :sock => self)
        end
      end
#      if self.model_activity_dataset
#        self.model_activity_dataset.save
#      else
#        xml = REXML::Document.new(self.value)
#        element_name = self.pod.pas_type == "model_activity_data" ? "modelactivitydata" : "OTModelActivityData"
#        self.create_model_activity_dataset :content => xml.elements["//#{element_name}"].to_s
#      end
    end
  end
  
  def has_model_activity_data?
    if self.pod.pas_type == "model_activity_data"
      return true
    elsif self.pod.pas_type == "ot_learner_data"
      if self.unpack_gzip_b64_value.match(/OTModelActivityData/)
        return true
      end
    end
    return false
  end

  def text(ignore_file = false)
    value = case self.pod.encoding
    when 'gzip+b64'
      self.unpack_gzip_b64_value(ignore_file)
    when 'escaped'
      self.unescape_value
    end
    case self.pod.mime_type
    when /xml/
      value ? value : self.value
    when /java_object/
      "java object: #{value.length.to_s} bytes"
    when /text/
      value ? value : self.value
    else
      "can't determine how to render this sock as text"
    end
  end    

  def unescape_value
    CGI.unescapeHTML(self.value)
  end

  def unpack_gzip_b64_value(ignore_file = false)
    begin
      if self.pod.bytearray?
        if ((! ignore_file) && File.exist?(self.path + self.filename_decoded))
          File.read(self.path + self.filename_decoded)
        else
          SDSUtil.b64gzip_unpack(self.value)
        end
      else
        ""
      end
    rescue => e
      if e == Zlib::GzipFile::Error
        $!
      else
        "Couldn't match the error: #{e}"
      end
    end
  end
  
  def process_ot_blob_resources(host = nil)
    update_url = false
    if (self.pod.rim_name != "ot.learner.data")
      return 0
    end
    num = 0
    if ! host
      uri = self.bundle.sds_return_address
      if uri
        host = uri.host
      end
    else
      update_url = true
    end
    bundle = self.bundle
    begin
      new_val = SDSUtil.extract_blob_resources(:data => self.value, :bundle => bundle, :host => host, :use_relative_url => bundle.can_blobs_use_relative_urls, :update_url => update_url)
      if new_val
        self.value = new_val
        self.save
      end
    rescue
      logger.warn "Couldn't modify sock entry #{self.id}"
    end
    return num 
  end

  # instance method returns filesystem path to
  # sock directory root
  def path
    "#{self.bundle.path}socks/"
  end
  
  def filename_raw
    "raw/sock_#{self.id.to_s}_#{self.pod.pas_type}_#{self.pod.encoding}"
  end

  def filename_decoded
    "decoded/sock_#{self.id.to_s}_#{self.pod.pas_type}.#{self.pod.extension}"
  end

  def save_to_file_system
    begin
      FileUtils.mkdir_p("#{self.path}raw") unless File.exists?("#{self.path}raw")
      File.open("#{self.path}#{filename_raw}", "w") { |f| f.write value }
      FileUtils.mkdir_p("#{self.path}decoded") unless File.exists?("#{self.path}decoded")
      File.open("#{self.path}#{self.filename_decoded}", "w") { |f| f.write text(true) }
    end
  end


end
