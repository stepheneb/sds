class Pod < ActiveRecord::Base
  set_table_name "sds_pods"
  has_and_belongs_to_many :sds_curnits, options = {:join_table => "sds_curnits_sds_pods"}

  belongs_to :curnit
  has_many :socks

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
    ['bytearray',        'ot.learner.data'    ] => ['application/xml+otrunk',               'gzip+b64',   'ot.learner.data',       'otml'],
    ['bytearray',        'otrunk_drawing'     ] => ['application/xml+otrunk-drawing',       'gzip+b64',   'otrunk_drawing',        'otml'],
    ['bytearray',        'trialData'          ] => ['java_object/gzip+b64',                 'gzip+b64',   'trial_data',            'pojo'],
    ['bytearray',        'findingsData'       ] => ['java_object/gzip+b64',                 'gzip+b64',   'findings_data',         'pojo'],
    ['bytearray',        ''                   ] => ['java_object/gzip+b64',                 'gzip+b64',   'generic_pas_object',    'pojo'],
    ['text',             'model.activity.data'] => ['application/xml+pas-modelreport',      'escaped',    'model.activity.data',   'xml' ],
    ['text',             'modelActivityData'  ] => ['application/xml+pas-modelreport',      'escaped',    'ModelActivityData',     'xml' ],
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
      mil
    else
      begin        
        podxml = self.curnit.find_podxml_in_jar(self.uuid)
        if USE_LIBXML # libxml version uses native Gnome xml library
          rim_id =  podxml.find("//void[@property='name'][string='#{self.rim_name}']/../@id").first.value #  example => "Rim0"
          response_id =  podxml.find("//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").first.content # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
          self.html_body =  podxml.find("//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").first.content
        else # use REXML
          rim_id =  REXML::XPath.first(podxml, "//void[@property='name'][string='#{self.rim_name}']/../@id").value #  example => "Rim0"
          response_id =  REXML::XPath.first(podxml, "//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").text # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
          self.html_body = REXML::XPath.first(podxml, "//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").text
        end
      rescue
        nil
      end
    end
  end
  
end

#  def note_question
#    @curnit.find_podxml_in_jar(self.uuid)   
#
#  def note_question
#    podxml = REXML::Document.new(File.new("/Users/stephen/dev/rails/sds/public/curnits/POD_#{self.uuid}.xml"))
#    rim_id =  REXML::XPath.first(podxml, "//void[@property='name'][string='#{self.rim_name}']/../@id").value #  example => "Rim0"
#    response_id =  REXML::XPath.first(podxml, "//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").text # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
#    html_prompt = REXML::XPath.first(podxml, "//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").text
#    Hpricot(html_prompt).at("body").inner_html
#  end
#  Pod.find_by_uuid_and_rim_name('dddddddd-6004-0040-0000-000000000000', 'undefined46')
