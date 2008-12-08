class PortalController < ApplicationController

  layout "standard"
  
  skip_before_filter :find_portal

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      @portal = Portal.new(ConvertXml.xml_to_hash(request.raw_post))
      if @portal.save
        response.headers['Location'] = url_for(:action => :show, :id => @portal.id)
        render(:xml => "", :status => 201) # Created
      else
        errors =  @portal.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
        render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
      end
    else
      @portals = Portal.search(params[:search], params[:page])
      respond_to do |wants|
        wants.html
        wants.xml { 
          portals = Portal.find(:all)
          render :xml => (portals.empty? ? "<portals />" : portals.to_xml(:except => ['created_at', 'updated_at']))
        }
      end
    end
  end

  def edit
    begin
      if request.post?
        params[:portal][:notification_listener_ids] ||= []
        @portal = Portal.find(params[:id])
        if @portal.update_attributes(params[:portal])
          flash[:notice] = "Portal #{@portal.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @portal = Portal.find(params[:id])
      end
    rescue => e
      flash[:notice] = "Portal #{@portal.id} does not exist. <!-- #{e}, #{e.backtrace.join("\n")} -->" 
      redirect_to :action => :list
    end
  end
  
  def create
    if request.post?
      @portal = Portal.new(params[:portal])
      if @portal.save
        flash[:notice] = "Portal #{@portal.id} was successfully created."
        redirect_to :action => 'list'
      else
        flash[:notice] = "Error creating Portal."
      end
    else
      @portal = Portal.new
    end
  end

  def show
    begin
      @portal = Portal.find(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @portal.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          if @portal.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
            response.headers['Location'] = url_for(:action => :show, :id => @portal.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @portal.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.delete?
        @portal.destroy
        render(:text => '', :status => 204) # No Content
      end
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end

#  def destroy
#    begin
#      Portal.find(params[:id]).destroy
#      flash[:notice] = "Portal #{@portal.id} was successfully deleted."
#    rescue
#      flash[:notice] = "Error deleting Portal #{@portal.id}." 
#      redirect_to :action => :list
#    end
#  end

end
