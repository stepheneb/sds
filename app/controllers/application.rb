# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  session :off, :if => proc { |request| (request.env['CONTENT_TYPE'] == "application/xml") || (request.env['HTTP_ACCEPT'] == "application/xml")}

  model :portal
  model :curnit
  model :jnlp
  model :offering
  model :sail_user
  model :workgroup
  model :bundle
  
  model :user
  model :sunflower_model
  model :sunflower_mystri_user
  
  require 'conversions'
  require 'convert'
  require 'to_xml'
  require 'net/http'
  require 'open-uri'

  filter_parameter_logging "password"

  include AuthenticatedSystem
  before_filter :find_portal
  before_filter :login_from_cookie
  before_filter :check_user

  after_filter :calc_content_length 

  # Pick a unique cookie name to distinguish our session data from other rails apps
  session :session_key => '_sds_session_id'
  
protected
  
  class Time
    def self.java8601(java_date)
      Time.xmlschema("#{java_date[0..-3]}:#{java_date[-2..-1]}")
    end

    def to_java8601
      ts = self.getlocal.xmlschema(3)
      ts[0..-4]+ts[-2..-1]
    end
  end
  
  def calc_content_length
    response.headers['Content-Length'] = response.body.length
  end
  
  def to_filename(name)
    name.strip.downcase.gsub(/\W+/, '_')
  end

  def find_portal
    unless @portal = Portal.find_by_id(params[:id])
      resource_not_found('Portal', params[:id], '')
    end
  end
  
  def find_portal_resource(klassname, id)
    if resource = eval("@portal.#{klassname.underscore.pluralize}.find_by_id(id)")
      resource
    else
      portal_resource_not_found(klassname, id)
    end
  end
  
  def portal_resource_not_found(resource, id)
    msg = "#{resource} #{id.to_s} does not exist in Portal: #{@portal.id.to_s}: #{@portal.name}."
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'list' }
      wants.xml { render(:text => "<error>#{msg}<error/>", :status => 404) } # Not Found
    end
    false
  end

  def external_resource_not_found(resource, id, url)
    msg = "#{resource} #{id.to_s}: external resource: #{url} not available."
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'list' }
      wants.xml { render(:text => "<error>#{msg}<error/>", :status => 404) } # Not Found
    end
    false
  end
    
  def find_portal
    unless @portal = Portal.find_by_id(params[:pid])
      resource_not_found('Portal', params[:id])
    end
  end
  
  def resource_not_found(resource, id, enclosing_resource=@portal)
    msg = "#{resource} #{id.to_s} can't be found"
    if enclosing_resource.blank?
       msg << '.'
       else
         msg << " in #{enclosing_resource.classname}: #{enclosing_resource.id.to_s}: #{enclosing_resource..name}."
       end
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'list' }
      wants.xml { render(:text => "<error>#{msg}<error/>", :status => 404) } # Not Found
    end
    false
  end
  
private

  def process_portal_realm
    @portal = if params[:pid] then Portal.find(params[:pid]) end
  end
 
  def check_user
    self.current_user = User.find_by_login('anonymous') unless logged_in?
#    self.current_user = User.find_by_login('anonymous', :include => :roles) unless logged_in?
  end

  def check_authentication
    if current_user.email == "anonymous"
      session[:intended_action] = [controller_name, action_name] 
      flash[:warning]  = "You need to be logged in first."
      redirect_to :controller => 'user', :action => 'login' 
    end
  end

  def log_referrer
    if request.env["HTTP_REFERER"]
      refer = request.env["HTTP_REFERER"]
      logger.info("\nREFERRER: " + refer.to_s + "\n")
    end
  end
 
end
