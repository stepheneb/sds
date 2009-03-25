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

  include ActionController::UrlWriter
  
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
          b64gzip_unpack(self.value)
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
  
  def process_ot_blob_resources
    if (self.pod.rim_name != "ot.learner.data")
      return 0
    end
    num = 0
    host = self.bundle.sds_return_address.host
    begin
      if USE_LIBXML
        @@xml_parser.string = b64gzip_unpack(self.value)
        ot_learner_data_xml = @@xml_parser.parse.root
        ot_learner_data_xml.find("//OTBlob/src").each do |raw|
          blob_content = raw.content
          next if (blob_content =~ /blobs\/[0-9]+\/raw\/[0-9a-zA-Z]+$/)
          num += 1
          if blob_content =~ /^gzb64:/
            blob_content = b64gzip_unpack(blob_content.sub(/^gzb64:/, ""))
          end
          blob = Blob.find_or_create_by_content(:content => blob_content, :bundle => self)
          raw.content = raw_blob_url(:id => blob, :token => blob.token, :host => host )
        end
        if num > 0
          self.value = b64gzip_pack(ot_learner_data_xml.to_s)
          self.save
        end
      else
        #   unpack it
        ot_learner_data_xml = REXML::Document.new(b64gzip_unpack(self.value)).root
        #   modify it
        ot_learner_data_xml.elements.each("//OTBlob/src") do |raw|
          blob_content = raw.text
          next if (blob_content =~ /blobs\/[0-9]+\/raw\/[0-9a-zA-Z]+$/)
          num += 1
          if blob_content =~ /^gzb64:/
            blob_content = b64gzip_unpack(blob_content.sub(/^gzb64:/, ""))
          end
          blob = Blob.find_or_create_by_content(:content => blob_content, :bundle => self)
          raw.text = raw_blob_url(:id => blob, :token => blob.token, :host => host )
        end
        if num > 0
          #   repack it and save it to the bundle contents
          self.value = b64gzip_pack(ot_learner_data_xml.to_s)
          self.save
        end
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
