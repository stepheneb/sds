class Pod < ActiveRecord::Base
  set_table_name "sds_pods"
  has_and_belongs_to_many :sds_curnits, options = {:join_table => "sds_curnits_sds_pods"}
  
  belongs_to :curnit
  has_many :socks
  
  require "rexml/document"
  require 'hpricot'

  before_save :check_for_note
  
  def get_html_body
    podxml = self.curnit.find_podxml_in_jar(self.id)
    rim_id =  REXML::XPath.first(podxml, "//void[@property='name'][string='#{self.rim_name}']/../@id").value #  example => "Rim0"
    response_id =  REXML::XPath.first(podxml, "//void[@property='rim']/object[@idref='#{rim_id}']/../../void[@property='identifier']/string").text # example => "MasterWorkNote(62288):NOTE_RESPONSE_1"
    self.html_body = REXML::XPath.first(podxml, "//void[@property='responseIdentifier'][string='#{response_id}']/../void[@property='prompt']/string").text
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
