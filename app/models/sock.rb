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

class Sock < ActiveRecord::Base
  set_table_name "sds_socks"
#  acts_as_reportable
  belongs_to :bundle
  belongs_to :pod
  has_one :model_activity_dataset
  

  def after_save
    self.save_to_file_system
    if self.pod.pas_type == "model_activity_data"
      if self.model_activity_dataset
        self.model_activity_dataset.save
      else
        self.create_model_activity_dataset
      end
    end
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
          Zlib::GzipReader.new(StringIO.new(self.value.unpack('m')[0])).read
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
      FileUtils.mkdir_p("#{self.path}decoded") unless File.exists?("#{self.path}deocded")
      File.open("#{self.path}#{self.filename_decoded}", "w") { |f| f.write text(true) }
    end
  end

end
