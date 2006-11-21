class HomeController < ApplicationController
    
  layout "standard"

  def index
    begin
      raise unless request.get?
      respond_to do |wants|
        wants.html
        wants.xml { render(:xml => "<text>Sail Data Service</text>\n", :status => 200) }
      end
    rescue
      render(:xml => "", :status => 400) # Bad Request
    end
  end

end
