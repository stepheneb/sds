# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include ExceptionNotifiable if EXCEPTION_NOTIFIER_CONFIGS_EXISTS
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery :secret => 'ace4fa914693f0739e588729756205e7'

  include AuthenticatedSystem
  before_filter :login_from_cookie
  # before_filter :check_user

  session :off, :if => proc { |request| (request.env['CONTENT_TYPE'] == "application/xml") || (request.env['HTTP_ACCEPT'] == "application/xml")}
  
  # require 'conversions'
  require 'convert'
  require 'net/http'
  require 'open-uri'

  filter_parameter_logging "password"

  around_filter :log_memory_filter
  
  before_filter :find_portal
  before_filter :setup_request_var
  # before_filter :log_headers
  before_filter :require_login_for_non_rest
 
  after_filter :calc_content_length
  # Pick a unique cookie name to distinguish our session data from other rails apps
  session :session_key => '_sds_session_id'
  
  # what happens when the user is not authorized to view a page/resource
  def permission_denied
    redirect_to(permission_denied_path)
  end
  
  def require_login_for_non_rest
    # if request is rest, just allow it for now
    respond_to do |format|
      format.xml { return true }
      format.html {
        if request.headers['CONTENT_TYPE'] == "application/xml"
          return true
        else
          return permission_required('researcher || admin')
        end
      }
    end
  end
 
   def setup_request_var
	   Thread.current[:request] = request
	 end
	
  def rescue_action_in_public(e)
    body = "<html><body><p><font color='red'>There was an error processing your request</font></p><p>\n<!-- #{e}\n #{e.backtrace.join("\n")} -->\n</p></body></html>"
    render(:text => body, :status => 500)
  end
 
  def log_headers
      request.headers.each do |k,v|
          logger.info "#{k} = #{v}"        
      end    
  end
  
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
    unless @portal = Portal.find_by_id(params[:pid])
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
    msg = "#{resource}: #{id.to_s} does not exist in Portal: #{@portal.id.to_s}: #{@portal.name}."
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'index' }
      wants.xml { render(:text => "<error>#{msg}</error>", :status => 404) } # Not Found
    end
    false # returing false in a controller filter stops the chain of proccessing
  end

  def external_resource_not_well_formed_xml(resource, id, url)
    msg = "#{resource} #{id.to_s}: external resource: #{url} not well-formed xml."
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'list' }
      wants.xml { render(:text => "<error>#{msg}</error>", :status => 404) } # Not Found
    end
    false
  end

  def external_resource_not_found(resource, id, url)
    msg = "#{resource} #{id.to_s}: external resource: #{url} not available."
    respond_to do |wants|
      wants.html { flash[:notice] = msg ; redirect_to :action => 'list' }
      wants.xml { render(:text => "<error>#{msg}</error>", :status => 404) } # Not Found
    end
    false
  end
    
  def find_portal
    unless @portal = Portal.find_by_id(params[:pid])
      # when it's a login, they don't have a portal and that's ok
      resource_not_found('Portal', params[:id]) unless params['action'] == 'login' || params['action'] == 'logout' || params['action'] == 'list'
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
      wants.xml { render(:text => "<error>#{msg}</error>", :status => 404) } # Not Found
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
    if self.current_user == :false || self.current_user.email == "anonymous"
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
  
  def log_memory_filter
    GC.disable
    start_mem = log_memory("START")
    yield
    log_memory("END", start_mem)
    GC.enable
    GC.start
  end

  def log_memory(cust, smem = 0)
    pid = Process.pid
    str = `ps -o vsz -p #{pid}`
    req = request.env["REQUEST_URI"]
    mem = str[/[0-9]+/]
    if smem == 0
      logger.info("#{cust} -- PID: #{pid} -- MEM: #{mem} -- METHOD: #{request.method.to_s} -- REQ: #{req}")
    else
      logger.info("#{cust} -- PID: #{pid} -- MEM: #{mem} -- DELTA: #{mem.to_i - smem.to_i} -- METHOD: #{request.method.to_s} -- REQ: #{req}")
    end
    return mem
  end
 
 # copied from rails/actionpack/lib/action_controller/request.rb
 # rails 2 made this method private!
 def parse_query_parameters(query_string)
   return {} if query_string.blank?

   pairs = query_string.split('&').collect do |chunk|
     next if chunk.empty?
     key, value = chunk.split('=', 2)
     next if key.empty?
     value = value.nil? ? nil : CGI.unescape(value)
     [ CGI.unescape(key), value ]
   end.compact

   ActionController::UrlEncodedPairParser.new(pairs).result
 end
end
