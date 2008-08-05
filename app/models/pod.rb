# == Schema Information
# Schema version: 58
#
# Table name: sds_pods
#
#  id        :integer(11)   not null, primary key
#  curnit_id :integer(11)   
#  uuid      :string(36)    
#  rim_name  :string(255)   
#  rim_shape :string(255)   
#  html_body :text          
#  mime_type :string(255)   
#  encoding  :string(255)   
#  pas_type  :string(255)   
#  extension :string(255)   
#

class Pod < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}pods"
  # has_and_belongs_to_many :curnits, options = {:join_table => "sds_curnits_sds_pods"}

  belongs_to :curnit
  has_many :socks
  has_many :bundles, :through => :socks

  has_many :offerings,
    :finder_sql => 'SELECT DISTINCT sds_offerings.* FROM sds_offerings
    INNER JOIN sds_workgroups ON sds_workgroups.offering_id = sds_offerings.id 
    INNER JOIN sds_bundles ON sds_bundles.workgroup_id = sds_workgroups.id
    INNER JOIN sds_socks ON sds_socks.bundle_id = sds_bundles.id    
    WHERE sds_socks.pod_id = #{id}'

  require "rexml/document"
  require 'hpricot'

  #  before_save :check_for_note

  def before_create
    self.attributes=(self.kind)
    if self.pas_type == 'note'
      self.html_body = self.get_html_body
    end
  end

  def after_save
    self.save_to_file_system
  end
  
  @@pod_shape_map = {'[B' => 'bytearray', '' => 'text'}
  @@pod_type_keys = ['mime_type', 'encoding', 'pas_type', 'extension']
  @@pod_type_map = {
    ['bytearray',        'ot.learner.data'    ] => ['application/xml+otrunk',               'gzip+b64',   'ot_learner_data',       'otml'],
    ['bytearray',        'otrunk_drawing'     ] => ['application/xml+otrunk-drawing',       'gzip+b64',   'otrunk_drawing',        'otml'],
    ['bytearray',        'trialData'          ] => ['java_object/gzip+b64',                 'gzip+b64',   'trial_data',            'pojo'],
    ['bytearray',        'findingsData'       ] => ['java_object/gzip+b64',                 'gzip+b64',   'findings_data',         'pojo'],
    ['bytearray',        ''                   ] => ['java_object/gzip+b64',                 'gzip+b64',   'generic_pas_object',    'pojo'],
    ['text',             'model.activity.data'] => ['application/xml+pas-modelreport',      'escaped',    'model_activity_data',   'xml' ],
    ['text',             'modelActivityData'  ] => ['application/xml+pas-modelreport',      'escaped',    'model_activity_data',   'xml' ],
    ['text',             'navigation_log'     ] => ['application/xml+pas-navigation-log',   'escaped',    'navigation_log',        'xml' ],
    ['text',             'curnit_map'         ] => ['application/xml+pas-curnit-map',       'escaped',    'curnit_map',            'xml' ],
    ['text',             'session_state'      ] => ['application/xml+pas-session-state',    'escaped',    'session_state',         'xml' ],
    ['text',             'airbag99'           ] => ['application/xml+svg',                  'escaped',    'pedraw',                'svg' ],
    ['text',             'airbag999'          ] => ['application/xml+svg',                  'escaped',    'pedraw',                'svg' ],
    ['text',             'undefined'          ] => ['text/plain',                           'escaped',    'note',                  'txt' ]
  }

  cattr_reader :pod_shape_map
  cattr_reader :pod_type_keys
  cattr_reader :pod_type_map
  
  # calculates and returns a hash: {:mime_type, :encoding, :pas_type, :extension]
  def kind
    shape = self.rim_shape
    name = self.rim_name
    name = name[/(undefined).*/, 1] || name
    Hash[*[@@pod_type_keys, @@pod_type_map[[shape, name]]].transpose.flatten]
  end

  def bytearray?
    self.rim_shape == 'bytearray'
  end

  # returns filesystem path to
  # pod directory root
  def path
    "#{self.curnit.path}pods/#{self.uuid}/"
  end
  
  def filename
    self.html_body.blank? ? nil : "#{self.rim_name}_body.html"
  end

  def save_to_file_system
    begin
      FileUtils.mkdir_p(self.path) unless File.exists?(self.path)
      unless self.filename.blank?
        File.open("#{self.path}#{filename}", "w") { |f| f.write self.html_body }
      end
    end
  end
  
  def get_html_body
    if self.curnit.local_jar_empty?
      nil
    else
      begin        
        podxml = self.curnit.find_podxml(self.uuid)
        if USE_LIBXML # libxml version uses native Gnome xml library
          rim_id =  podxml.find("//void[@property='name'][string='#{self.rim_name}']/../@id").first.value #  example => "Rim0"
          begin
            response_id =  podxml.find("//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").first.content # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
          rescue
            response_id =  podxml.find("//void[@property='rim']/object[@id='#{rim_id}']/../../void[@property='identifier']/string").first.content # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
          end
          html_doc =  podxml.find("//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").first.content
        else # use REXML
          rim_id =  REXML::XPath.first(podxml, "//void[@property='name'][string='#{self.rim_name}']/../@id").value #  example => "Rim0"
          response_id =  REXML::XPath.first(podxml, "//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").text # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
          html_doc = REXML::XPath.first(podxml, "//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").text
        end
        doc = Hpricot(html_doc)
        self.html_body = doc.search("body").inner_html
      rescue
        nil
      end
    end
  end  
end

#  def note_question
#    @curnit.find_podxml(self.uuid)   
#
#  def note_question
#    podxml = REXML::Document.new(File.new("/Users/stephen/dev/rails/sds/public/curnits/POD_#{self.uuid}.xml"))
#    rim_id =  REXML::XPath.first(podxml, "//void[@property='name'][string='#{self.rim_name}']/../@id").value #  example => "Rim0"
#    response_id =  REXML::XPath.first(podxml, "//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").text # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
#    html_prompt = REXML::XPath.first(podxml, "//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").text
#    Hpricot(html_prompt).at("body").inner_html
#  end
#  Pod.find_by_uuid_and_rim_name('dddddddd-6004-0040-0000-000000000000', 'undefined46')
