class HomeController < ApplicationController
    
  layout "standard"
  
  skip_before_filter :find_portal
  skip_before_filter :require_login_for_non_rest

  def index
    if params[:pid]
      find_portal
    end
    begin
      raise unless request.get?
      respond_to do |wants|
        wants.html
        wants.xml { render :inline => "xml.sds do xml.name('Sail Data Service') ; xml.version('1.1') end", :type => :rxml  }
      end
    rescue => e
      render(:xml => "", :status => 400) # Bad Request
    end
  end
end
