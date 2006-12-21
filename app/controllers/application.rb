# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  session :off, :if => proc { |request| (request.env['CONTENT_TYPE'] == "application/xml") || (request.env['HTTP_ACCEPT'] == "application/xml")}

  model :portal
  model :curnit
  model :jnlp
  model :offering
  model :user
  model :workgroup
  model :bundle
  
  model :sds_user
  model :sunflower_model
  model :sunflower_mystri_user
  
  require 'conversions'
  require 'convert'
  require 'to_xml'
  require 'net/http'

  filter_parameter_logging "password"

  include AuthenticatedSystem
  before_filter :login_from_cookie
  before_filter :check_sds_user

  after_filter :calc_content_length 
    
protected
  
  def calc_content_length
    response.headers['Content-Length'] = response.body.length
  end
  
private

  def check_sds_user
    self.current_sds_user = SdsUser.find_by_login('anonymous') unless logged_in?
#    self.current_sds_user = User.find_by_login('anonymous', :include => :roles) unless logged_in?
  end

  def check_authentication
    if current_sds_user.email == "anonymous"
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
