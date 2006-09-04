# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
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
  
end
