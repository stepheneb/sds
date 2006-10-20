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
  
  require 'conversions'
  require 'convert'
  require 'to_xml'
 
  private

  def log_referrer
    logger.info("\nREFERRER: " + request.env["HTTP_REFERER"] + "\n")
  end
 
end
