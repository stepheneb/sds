class HomeController < ApplicationController
    
  layout "standard"
  
  skip_before_filter :find_portal

  def index
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
